# Package List Reference

This document lists all packages installed by the `install.sh` script, organized by category.

## Base Packages
- `base-devel` - Development tools
- `libx11` - X11 client library
- `libxft` - FreeType-based font drawing library
- `libxinerama` - X11 Xinerama extension library
- `freetype2` - Font rendering library
- `xorg` - X.Org X server

## Application Packages

### Core Applications
- `sxhkd` - Simple X hotkey daemon
- `polkit-gnome` - PolicyKit authentication agent (lightweight, GTK-based)
- `ly` - Display manager
- `thunar` - File manager
- `xcolor` - Color picker
- `feh` - Image viewer and wallpaper setter
- `picom` - Compositor for X11
- `dmenu` - Dynamic menu for X
- `betterlockscreen` - Lock screen utility
- `cursor-bin` - Code editor (AI-powered editor)
- `network-manager-applet` - NetworkManager applet
- `gvfs` - Virtual filesystem implementation
- `alacritty` - GPU-accelerated terminal emulator
- `neovim` - Hyperextensible Vim-based text editor
- `vlc` - Media player

### Utilities
- `satty` - Screenshot tool
- `dunst` - Notification daemon
- `tmux` - Terminal multiplexer
- `vim` - Text editor
- `htop` - Interactive process viewer
- `tree` - Directory tree viewer
- `lazygit` - Git TUI
- `dust` - Disk usage analyzer
- `trash-cli` - Command line trash utility

### Media
- `ffmpeg` - Multimedia framework
- `mpv` - Media player
- `playerctl` - Media player controller
- `pamixer` - PulseAudio mixer
- `pavucontrol` - PulseAudio volume control
- `ffmpegthumbnailer` - Video thumbnail generator

### System Tools
- `brightnessctl` - Brightness control
- `xkblayout-state-git` - Keyboard layout switcher
- `timeshift` - System restore tool
- `cpupower` - CPU frequency and governor control (configured for maximum performance)
- `opendoas` - Doas (sudo alternative)

**Note:** Power management is configured for maximum performance (always plugged in). If you need power saving features, you can install `tlp` and `auto-cpufreq` separately.

### Development
- `rust` - Rust programming language
- `cargo` - Rust package manager
- `nodejs` - JavaScript runtime
- `npm` - Node package manager
- `python-pip` - Python package installer

### File Management
- `unzip` - ZIP archive extractor
- `unrar` - RAR archive extractor
- `gparted` - Partition editor
- `thunar-archive-plugin` - Archive plugin for Thunar
- `tumbler` - Thumbnail service
- `zsync` - File transfer tool

### Other
- `firefox` - Firefox web browser
- `obsidian` - Obsidian - Knowledge base
- `localsend-bin` - LocalSend - Share files to nearby devices (AUR)
- `spotify` - Spotify music player (via AUR)

**Optional AUR packages** (may not be available or may need manual installation):
- `stremio` - Stremio - Media center
- `freedownloadmanager` - Free Download Manager
- `gruvbox-dark-gtk` - Gruvbox Dark GTK theme
- `figlet` - ASCII art generator
- `jq` - JSON processor
- `xdg-user-dirs` - User directories
- `pacman-contrib` - Pacman utilities

## Font Packages

### Nerd Fonts (with icons)
- `ttf-jetbrains-mono-nerd` - JetBrains Mono Nerd Font

### Emoji & Symbols
- `noto-fonts-emoji` - Noto emoji fonts
- `noto-fonts` - Noto fonts (Arabic/English support)

**Note:** Additional fonts can be installed manually if needed. Popular options include:
- `ttf-cascadia-code-nerd` - Cascadia Code Nerd Font
- `ttf-mononoki-nerd` - Mononoki Nerd Font
- `noto-fonts-cjk` - Noto CJK fonts

## Icon Theme Packages

- `tela-circle-icon-theme-dracula` - Tela Circle Dracula icons
- `tela-circle-icon-theme-standard` - Tela Circle Standard icons
- `papirus-icon-theme` - Papirus icon theme
- `adwaita-icon-theme` - Adwaita icon theme

## Cursor Theme Packages

- `bibata-cursor-theme` - Bibata cursor theme

## GTK Theme Packages

- `catppuccin-gtk-theme-mocha` - Catppuccin Mocha theme (AUR)
- `catppuccin-gtk-theme-frappe` - Catppuccin Frappe theme (AUR)

**Optional GTK themes** (may need manual installation):
- `gruvbox-dark-gtk` - Gruvbox Dark theme (AUR)

## Cursor Extensions

These are installed via the `cursor` command (Cursor uses the same extension marketplace as VSCode):

### Language & Framework Support
- `ms-python.python` - Python language support
- `ms-python.debugpy` - Python debugger
- `ms-python.black-formatter` - Black Python formatter
- `charliermarsh.ruff` - Ruff Python linter
- `anysphere.cursorpyright` - Cursor Python language server
- `typescriptteam.native-preview` - TypeScript preview
- `graphql.vscode-graphql` - GraphQL support
- `graphql.vscode-graphql-syntax` - GraphQL syntax highlighting
- `redhat.vscode-yaml` - YAML language support

### Code Quality & Formatting
- `dbaeumer.vscode-eslint` - ESLint JavaScript linter
- `esbenp.prettier-vscode` - Prettier code formatter
- `usernamehw.errorlens` - Error highlighting
- `editorconfig.editorconfig` - EditorConfig support

### Development Tools
- `eamodio.gitlens` - Git supercharged
- `christian-kohler.path-intellisense` - Path autocomplete
- `mikestead.dotenv` - .env file support
- `bradlc.vscode-tailwindcss` - Tailwind CSS IntelliSense

### Container & Database
- `ms-azuretools.vscode-docker` - Docker support
- `ms-azuretools.vscode-containers` - Container support
- `rphlmr.vscode-drizzle-orm` - Drizzle ORM support

## Optional Packages

### Bluetooth (optional)
- `bluez` - Bluetooth stack
- `bluez-utils` - Bluetooth utilities
- `blueman` - Bluetooth manager

## Notes

- Most packages are installed from the official Arch repositories
- Some packages (marked with `-git` or `-bin`) are from AUR
- Fonts, themes, and icons are installed system-wide to `/usr/share/`
- User-specific fonts can be installed to `~/.local/share/fonts/`

## Updating Packages

To update all packages:

```bash
yay -Syu
```

To update AUR packages only:

```bash
yay -Sua
```

