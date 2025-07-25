#!/bin/bash

# Generate categorized release notes from conventional commits since last tag
# Usage: scripts/generate-release-notes.sh [options] [tag-range]
# Output: release_notes.md
#
# Arguments:
#   tag-range   Git range like 'v1.0.0..HEAD' (optional, auto-detects if omitted)
#
# Options:
#   --help      Show this help message
#
# Examples:
#   scripts/generate-release-notes.sh                    # Auto-detect range from last tag
#   scripts/generate-release-notes.sh v0.1.0..HEAD      # Specify custom range
#   scripts/generate-release-notes.sh --help            # Show help
#
# The script categorizes conventional commits into sections like:
#   - Features (feat:)
#   - Bug Fixes (fix:)  
#   - Documentation (docs:)
#   - Build System (build:)
#   - And other commit types

set -euo pipefail

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            sed -n '3,22p' "$0" | sed 's/^# //' | sed 's/^#$//'
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

# Get the range to analyze
if [ $# -eq 1 ]; then
    if [[ "$1" == *..* ]]; then
        RANGE="$1"
    else
        RANGE="${1}..HEAD"
    fi
else
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [ -z "${LAST_TAG}" ]; then
        echo "No tags found. Please specify a range like 'v1.0.0..HEAD' or create a tag first."
        exit 1
    fi
    RANGE="${LAST_TAG}..HEAD"
fi

echo "Generating release notes for range: ${RANGE}"

# Create temporary file for processing
TEMP_FILE=$(mktemp)
trap 'rm -f "${TEMP_FILE}"' EXIT

# Extract conventional commits
git log "${RANGE}" --pretty=format:"%s" | \
    grep -E "^[a-z]+(\([^)]+\))?!?: " > "${TEMP_FILE}" || {
    echo "No conventional commits found in range ${RANGE}"
    echo "# Release Notes" > release_notes.md
    echo "" >> release_notes.md
    echo "No conventional commits found." >> release_notes.md
    exit 0
}

# Start the release notes file
echo "# Release Notes" > release_notes.md
echo "" >> release_notes.md

# Extract all unique commit types (ignoring scope and breaking change indicator)
TYPES=$(sed -E 's/^([a-z]+)(\([^)]+\))?!?: .*/\1/' "${TEMP_FILE}" | sort -u)

# Process each type
for TYPE in ${TYPES}; do
    # Get all commits for this type
    COMMITS=$(grep -E "^${TYPE}(\([^)]+\))?!?: " "${TEMP_FILE}" | sed 's/^/- /')
    
    if [ -n "${COMMITS}" ]; then
        # Capitalize first letter for heading
        HEADING=$(echo "${TYPE}" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
        echo "## ${HEADING}" >> release_notes.md
        echo "" >> release_notes.md
        echo "${COMMITS}" >> release_notes.md
        echo "" >> release_notes.md
    fi
done

# Handle breaking changes separately if any
BREAKING_COMMITS=$(grep "!: " "${TEMP_FILE}" | sed 's/^/- /' || true)
if [ -n "${BREAKING_COMMITS}" ]; then
    echo "## BREAKING CHANGES" >> release_notes.md
    echo "" >> release_notes.md
    echo "${BREAKING_COMMITS}" >> release_notes.md
    echo "" >> release_notes.md
fi

echo "Release notes generated in release_notes.md"
echo ""
echo "To create a GitHub release:"
echo "gh release create v<VERSION> --notes-file release_notes.md"