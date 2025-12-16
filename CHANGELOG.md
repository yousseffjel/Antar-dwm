# Changelog

## [Unreleased] - Cleanup and Update

### Fixed
- Fixed undefined variables (`$NC`, `$NONE`) in install.sh
- Fixed error handling and logging in install.sh
- Fixed hard-coded username in doas.conf (now uses current user)
- Fixed hard-coded paths in sxhkdrc (now uses `$HOME`)
- Fixed autostart.sh to properly background all processes
- Fixed betterlockscreen setup to be optional and portable
- Removed redundant dunstrc file (merged into dunst.conf)

### Added
- Created helper scripts directory with:
  - `logout.sh` - Session management menu
  - `mountmenu.sh` - Device mounting interface
  - `umountmenu.sh` - Device unmounting interface
  - `wallpaper.sh` - Random wallpaper setter
- Added comprehensive README.md with full documentation
- Added .gitignore file
- Added installation of helper scripts to ~/src/bin/
- Added dmenu to package list (required for helper scripts)
- Added user-friendly messages during installation

### Changed
- Made all paths portable (no hard-coded usernames or user-specific paths)
- Improved doas.conf security (uses `persist` instead of `nopass`)
- Made wallpaper setup optional and automatic detection
- Improved error handling throughout install.sh
- Better cleanup of temporary yay build directory
- Updated sxhkdrc to use portable paths and fallbacks

### Security
- Changed doas.conf from `nopass` to `persist` (more secure)
- Made doas.conf user-agnostic (uses current username)

### Documentation
- Complete README with installation instructions
- Troubleshooting section
- Keybindings reference
- Configuration guide
- Project structure overview

