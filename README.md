# Linux Profile Setup

A shell profile management system that automatically installs and configures custom shell functions and configuration files across different Unix-like systems.

## Purpose

This repository provides a streamlined way to deploy and manage personal shell configurations, functions, and scripts across multiple environments. It handles the complexity of different shell profile locations and ensures your custom tools are available wherever you work.

## Features

### Core Functionality
- **Automatic Profile Detection**: Intelligently finds and updates `.profile` or `.bash_profile`
- **Cross-Platform Compatibility**: Works on Linux, macOS, and WSL environments
- **Safe Installation**: Creates backups and uses boundary markers for clean management
- **Selective Configuration**: Exclude specific files from being sourced via configuration

### Included Tools

#### Directory Navigation Functions (`bin/directory.fn`)
- **`upto <directory>`**: Navigate up the directory tree to a specific parent directory
- **`jd <directory>`**: Jump to any subdirectory using glob patterns
- **Tab Completion**: Intelligent completion for the `upto` command

### Installation Management
- **Boundary Markers**: Uses header/footer comments to manage installed content
- **Conflict Resolution**: Detects and handles existing installations safely
- **Rollback Support**: Maintains profile backups for easy restoration

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd linux-profile
   ```

2. **Run the setup script**:
   ```bash
   ./setup.sh
   ```

3. **Reload your shell** or source your profile:
   ```bash
   source ~/.profile
   # or
   source ~/.bash_profile
   ```

## Configuration

### Profile Properties (`profile.properties`)
The setup behavior is controlled by variables in `profile.properties`:

- `COPY_CONF_TO`: Target directory for configuration files (default: `$HOME`)
- `COPY_BIN_TO`: Target directory for executable scripts (default: `$HOME/bin`)
- `EXCLUSIONS`: Space-separated list of files to exclude from sourcing

### Directory Structure
```
linux-profile/
├── setup.sh           # Main installation script
├── profile.properties  # Configuration settings
├── bin/               # Executable scripts and functions
│   └── directory.fn   # Directory navigation functions
├── conf/              # Configuration files (currently empty)
└── LICENSE           # MIT License
```

## How It Works

1. **Backup**: Creates a backup of your existing profile
2. **Boundary Detection**: Checks for existing installation markers
3. **File Copying**: Copies files from `bin/` and `conf/` to configured locations
4. **Profile Update**: Adds source statements between boundary markers
5. **Activation**: Sources the updated profile

## Safety Features

- **Backup Creation**: Original profile is backed up before modification
- **Boundary Markers**: Installation is contained within clearly marked sections
- **State Validation**: Prevents operation on profiles in inconsistent states
- **Error Handling**: Exits safely if critical files are missing

## Usage Examples

After installation, you can use the included directory navigation functions:

```bash
# Navigate up to the 'src' directory in your current path
upto src

# Jump to any 'tests' directory below current location
jd tests

# Use tab completion with upto
upto <TAB>  # Shows available parent directories
```

## Uninstallation

To remove the installed configuration:

1. Restore from backup:
   ```bash
   cp ~/.profile.bak ~/.profile
   # or
   cp ~/.bash_profile.bak ~/.bash_profile
   ```

2. Remove copied files from `$HOME/bin/` if desired

## Requirements

- Bash shell
- Standard Unix utilities (`sed`, `grep`, `find`, `cp`)
- Write access to home directory and profile files

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Feel free to submit issues and enhancement requests. When contributing:

1. Test changes across different platforms (Linux/macOS)
2. Ensure shellcheck compliance
3. Maintain backward compatibility
4. Update documentation as needed