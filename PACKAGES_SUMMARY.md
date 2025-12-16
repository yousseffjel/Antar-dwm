# Package Installation Summary

## File Manager & Archive Support (Full)

### File Manager
- **thunar** - Lightweight file manager
- **thunar-archive-plugin** - Archive support in Thunar (right-click extract/create)
- **tumbler** - Thumbnail service for Thunar
- **file-roller** - Archive manager GUI (alternative to command-line tools)
- **gvfs** - Virtual filesystem (enables network shares, MTP, etc.)

### Archive Extraction Tools
- **unzip** - Extract ZIP archives
- **unrar** - Extract RAR archives  
- **p7zip** - Extract/create 7z, ZIP, GZIP, BZIP2, TAR archives
- **zip** - Create ZIP archives
- **tar** - Extract/create TAR, GZIP, BZIP2 archives (already in base)

### Supported Archive Formats
✅ ZIP (.zip)
✅ RAR (.rar)
✅ 7Z (.7z)
✅ TAR (.tar)
✅ GZIP (.tar.gz, .gz)
✅ BZIP2 (.tar.bz2, .bz2)
✅ XZ (.tar.xz, .xz)

## Terminal Configuration

### Main Terminal
- **alacritty** - GPU-accelerated terminal emulator (main terminal)
  - Used by default in dwm
  - Used in scratchpad
  - Set in helpers.rc

### Secondary Terminal
- **st** - Simple terminal from suckless (installed from AUR)
  - Available as fallback
  - Lightweight alternative

## Complete Package List

### Core System
- base-devel, libx11, libxft, libxinerama, freetype2, xorg-server

### Applications
- sxhkd, polkit-gnome, ly, xcolor, feh, picom, wget
- vim, neovim, tmux, lxappearance, network-manager-applet
- satty, dunst, libnotify, xclip
- brightnessctl, pamixer, pavucontrol
- htop, xdg-user-dirs, pacman-contrib
- opendoas, xsel
- curl, tree, binutils, coreutils, fuse2

### Development Tools
- rust, cargo, nodejs, npm

### Fonts
- ttf-jetbrains-mono-nerd (global font)

### Icons & Themes
- papirus-icon-theme, adwaita-icon-theme
- bibata-cursor-theme (AUR)
- tela-circle-icon-theme-dracula (AUR)
- catppuccin-gtk-theme-mocha, catppuccin-gtk-theme-frappe (AUR)

### AUR Packages
- cursor-bin, betterlockscreen
- xkblayout-state-git
- st (simple terminal)

## Usage

### Extracting Archives in Thunar
1. Right-click on archive file
2. Select "Extract Here" or "Extract To..."
3. Works with ZIP, RAR, 7Z, TAR, and compressed TAR files

### Command Line Archive Tools
```bash
# Extract ZIP
unzip file.zip

# Extract RAR
unrar x file.rar

# Extract 7Z
7z x file.7z

# Extract TAR
tar -xf file.tar
tar -xzf file.tar.gz
tar -xjf file.tar.bz2
tar -xJf file.tar.xz

# Create archives
zip -r archive.zip folder/
7z a archive.7z folder/
tar -czf archive.tar.gz folder/
```

### Terminal Usage
- **Default**: Alacritty opens when pressing Super+Enter
- **Scratchpad**: Alacritty with tmux opens in scratchpad
- **Fallback**: st is available if alacritty is not found
