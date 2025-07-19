#!/bin/bash

# Create a new GitHub release with auto-generated changelog
# Usage: ./create-release.sh [options] [version] [title]
# 
# Options:
#   --auto      Automatically calculate version and create release without prompts
#   --dry-run   Show what would happen without creating the release
#   --help      Show this help message
#
# Examples:
#   ./create-release.sh                    # Interactive mode (suggests version)
#   ./create-release.sh --auto             # Automatic mode (no prompts)
#   ./create-release.sh --dry-run          # Preview calculated version and notes
#   ./create-release.sh v0.2.0 "Title"    # Manual version specification

set -euo pipefail

# Default options
AUTO_MODE=false
DRY_RUN=false
MANUAL_VERSION=""
TITLE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto)
            AUTO_MODE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            sed -n '3,15p' "$0" | sed 's/^# //'
            exit 0
            ;;
        v*)
            MANUAL_VERSION="$1"
            shift
            if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
                TITLE="$1"
                shift
            fi
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if gh is installed (skip for dry-run)
if [ "$DRY_RUN" = false ] && ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is not installed. Please install it first:"
    echo "  brew install gh"
    echo "  # or download from https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated with gh (skip for dry-run)
if [ "$DRY_RUN" = false ] && ! gh auth status >/dev/null 2>&1; then
    echo "Error: Not authenticated with GitHub CLI. Please run:"
    echo "  gh auth login"
    exit 1
fi

# Function to calculate next semantic version
calculate_next_version() {
    local last_tag="$1"
    local range="$2"
    
    # Parse current version (remove 'v' prefix if present)
    local current_version="${last_tag#v}"
    
    # Default to 0.0.0 if no previous tag
    if [ -z "$current_version" ]; then
        current_version="0.0.0"
    fi
    
    # Extract major.minor.patch
    IFS='.' read -ra VERSION_PARTS <<< "$current_version"
    local major="${VERSION_PARTS[0]:-0}"
    local minor="${VERSION_PARTS[1]:-0}"
    local patch="${VERSION_PARTS[2]:-0}"
    
    # Remove any pre-release or build metadata from patch
    patch="${patch%%-*}"
    patch="${patch%%+*}"
    
    # Analyze commits to determine version bump
    local has_breaking=false
    local has_feat=false
    local has_fix=false
    local has_other=false
    
    if [ "$range" = "HEAD" ]; then
        # No previous tags, analyze all commits
        local commits=$(git log --pretty=format:"%s" 2>/dev/null || echo "")
    else
        local commits=$(git log "$range" --pretty=format:"%s" 2>/dev/null || echo "")
    fi
    
    while IFS= read -r commit; do
        if [[ "$commit" =~ BREAKING ]] || [[ "$commit" =~ !: ]]; then
            has_breaking=true
        elif [[ "$commit" =~ ^feat ]]; then
            has_feat=true
        elif [[ "$commit" =~ ^fix ]]; then
            has_fix=true
        elif [[ "$commit" =~ ^[a-z]+.*: ]]; then
            has_other=true
        fi
    done <<< "$commits"
    
    # Determine version bump and return both version and type
    if [ "$has_breaking" = true ]; then
        # Major version bump
        printf "v%d.0.0|BREAKING" "$((major + 1))"
    elif [ "$has_feat" = true ]; then
        # Minor version bump
        printf "v%d.%d.0|MINOR" "$major" "$((minor + 1))"
    elif [ "$has_fix" = true ]; then
        # Patch version bump
        printf "v%d.%d.%d|PATCH" "$major" "$minor" "$((patch + 1))"
    elif [ "$has_other" = true ]; then
        # Patch version bump for other conventional commits
        printf "v%d.%d.%d|PATCH" "$major" "$minor" "$((patch + 1))"
    else
        # No conventional commits found
        printf "v%d.%d.%d|PATCH" "$major" "$minor" "$((patch + 1))"
    fi
}

# Get the last tag to determine range
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LAST_TAG" ]; then
    echo "No previous tags found."
    RANGE="HEAD"
else
    echo "Last release: $LAST_TAG"
    RANGE="${LAST_TAG}..HEAD"
fi

# Check if there are any commits in the range
if [ "$RANGE" != "HEAD" ]; then
    COMMIT_COUNT=$(git rev-list --count "$RANGE" 2>/dev/null || echo "0")
    if [ "$COMMIT_COUNT" -eq 0 ]; then
        echo "No new commits since $LAST_TAG. Nothing to release."
        exit 1
    fi
    echo "Found $COMMIT_COUNT new commits to include in release."
fi

# Determine version to use
if [ -n "$MANUAL_VERSION" ]; then
    # Manual version provided
    VERSION="$MANUAL_VERSION"
    if [ -z "$TITLE" ]; then
        TITLE="$VERSION"
    fi
    echo "Using manually specified version: $VERSION"
else
    # Calculate next version automatically
    echo "Analyzing commits to determine next version..."
    
    # Get calculated version and bump type
    CALC_RESULT=$(calculate_next_version "$LAST_TAG" "$RANGE")
    CALCULATED_VERSION=$(echo "$CALC_RESULT" | cut -d'|' -f1)
    BUMP_TYPE=$(echo "$CALC_RESULT" | cut -d'|' -f2)
    
    echo "Suggested version: $CALCULATED_VERSION (${BUMP_TYPE} bump)"
    
    if [ "$AUTO_MODE" = true ] || [ "$DRY_RUN" = true ]; then
        VERSION="$CALCULATED_VERSION"
        TITLE="$VERSION"
        echo "Using calculated version: $VERSION"
    else
        # Interactive mode - ask user
        read -p "Use suggested version $CALCULATED_VERSION? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            read -p "Enter custom version: " VERSION
            if [ -z "$VERSION" ]; then
                echo "No version provided. Exiting."
                exit 1
            fi
        else
            VERSION="$CALCULATED_VERSION"
        fi
        
        if [ -z "$TITLE" ]; then
            read -p "Enter release title (or press Enter for '$VERSION'): " TITLE
            if [ -z "$TITLE" ]; then
                TITLE="$VERSION"
            fi
        fi
    fi
fi

# Validate version format (should start with v)
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
    echo "Warning: Version should follow semantic versioning format (e.g., v1.0.0)"
    if [ "$AUTO_MODE" = false ] && [ "$DRY_RUN" = false ]; then
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Create temporary file for release notes
TEMP_NOTES=$(mktemp)
trap 'rm -f "$TEMP_NOTES" release_notes.md' EXIT

echo "Generating release notes..."

# Try git-cliff first, fall back to custom script
if command -v git-cliff >/dev/null 2>&1; then
    echo "Using git-cliff to generate changelog..."
    if [ "$RANGE" = "HEAD" ]; then
        git-cliff --strip header --output "$TEMP_NOTES" 2>/dev/null || {
            echo "git-cliff failed, falling back to custom script..."
            ./generate-release-notes.sh > /dev/null 2>&1
            cp release_notes.md "$TEMP_NOTES"
        }
    else
        git-cliff "$RANGE" --strip header --output "$TEMP_NOTES" 2>/dev/null || {
            echo "git-cliff failed, falling back to custom script..."
            ./generate-release-notes.sh "$RANGE" > /dev/null 2>&1
            cp release_notes.md "$TEMP_NOTES"
        }
    fi
else
    echo "git-cliff not found, using custom script..."
    if [ "$RANGE" = "HEAD" ]; then
        ./generate-release-notes.sh > /dev/null 2>&1
    else
        ./generate-release-notes.sh "$RANGE" > /dev/null 2>&1
    fi
    cp release_notes.md "$TEMP_NOTES"
fi

# Check if release notes were generated
if [ ! -s "$TEMP_NOTES" ]; then
    echo "# Release Notes" > "$TEMP_NOTES"
    echo "" >> "$TEMP_NOTES"
    echo "No conventional commits found for this release." >> "$TEMP_NOTES"
fi

echo ""
echo "Release Summary:"
echo "================"
echo "Version: $VERSION"
echo "Title: $TITLE"
echo "Range: $RANGE"
echo ""
echo "Release Notes:"
echo "=============="
cat "$TEMP_NOTES"
echo "=============="
echo

# Handle dry-run mode
if [ "$DRY_RUN" = true ]; then
    echo "🔍 DRY RUN: Would create release $VERSION with the above notes"
    echo "   To actually create the release, run without --dry-run"
    exit 0
fi

# Confirm release creation (skip in auto mode)
if [ "$AUTO_MODE" = false ]; then
    read -p "Create release $VERSION with these notes? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Release creation cancelled."
        exit 0
    fi
fi

# Create the GitHub release
echo "Creating GitHub release..."
if gh release create "$VERSION" --title "$TITLE" --notes-file "$TEMP_NOTES"; then
    echo "✅ Release $VERSION created successfully!"
    echo "🔗 View at: https://github.com/$(gh repo view --json owner,name -q '.owner.login + "/" + .name')/releases/tag/$VERSION"
else
    echo "❌ Failed to create release. Check your permissions and try again."
    exit 1
fi

echo "🧹 Cleaning up temporary files..."