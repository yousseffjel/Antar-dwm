# Antar-dwm

A complete, automated setup for a beautiful and functional dwm (Dynamic Window Manager) desktop environment on Arch Linux.

## Overview

This project provides a one-command installation script that sets up a fully configured dwm-based desktop environment with:

- **Window Manager**: dwm (Dynamic Window Manager)
- **Compositor**: picom with rounded corners and blur effects
- **Hotkey Daemon**: sxhkd for application launching and system control
- **Terminal**: Alacritty (GPU-accelerated terminal emulator)
- **Notifications**: Dunst with modern styling
- **Status Bar**: slstatus (you'll need to configure/build this separately)
- **Themes**: Multiple GTK themes, icon themes, and cursor themes
- **Fonts**: Nerd Fonts and other programming fonts
- **Power Management**: Optional aggressive performance mode (CPU governor, USB/PCIe settings)
- **Additional Tools**: tmux, betterlockscreen, and more

## Features

- 🎨 **Beautiful Aesthetics**: Rounded corners, blur effects, and modern theming
- ⌨️ **Keyboard-Driven**: Extensive sxhkd keybindings for efficient workflow
- 🚀 **One-Command Setup**: Automated installation script handles everything
- 🎯 **Curated Packages**: Pre-selected essential applications and utilities
- 🔧 **Highly Customizable**: All configuration files are easily accessible

## Prerequisites

- **Arch Linux** (or Arch-based distribution)
- **Internet connection** (for package downloads)
- **sudo/doas access** (for system-level installations)
- **Basic familiarity with Linux** (recommended)

## Installation

1. **Clone this repository:**
   ```bash
   git clone https://github.com/yourusername/Antar-dwm.git
   cd Antar-dwm
   ```

2. **Make the install script executable:**
   ```bash
   chmod +x install.sh
   ```

3. **Run the installation script:**
   ```bash
   ./install.sh
   ```

   The script will:
   - Update your system and optimize package mirrors
   - Install yay (AUR helper) if not present
   - Install all required packages (apps, fonts, themes, icons)
   - Link configuration files to your home directory
   - Install Cursor extensions (uses same marketplace as VSCode)
   - Configure power management
   - Set up helper scripts

4. **Reboot your system** (recommended after installation)

5. **Select dwm session** from your display manager (ly, SDDM, etc.)

## Post-Installation

### Setting Up dwm

This repository provides the desktop environment configuration, but **dwm itself** needs to be built and installed separately. You can:

1. Install from AUR:
   ```bash
   yay -S dwm
   ```

2. Or build from source (recommended for customization):
   ```bash
   git clone https://git.suckless.org/dwm
   cd dwm
   # Apply your patches, edit config.h, then:
   sudo make clean install
   ```

### Setting Up slstatus

Similarly, **slstatus** (status bar) needs to be installed separately:

```bash
yay -S slstatus
# Or build from source: https://git.suckless.org/slstatus
```

### Setting Up Wallpapers

Create a wallpaper directory and add your images:

```bash
mkdir -p ~/Pictures/Wallpapers
# Add your wallpaper images here
betterlockscreen -u ~/Pictures/Wallpapers/your-image.jpg --blur
```

### Setting Up Helper Scripts

The installation script installs helper scripts to `~/src/bin/`. These include:

- `logout.sh` - Session management (logout/reboot/shutdown)
- `mountmenu.sh` - Mount devices via dmenu
- `umountmenu.sh` - Unmount devices via dmenu
- `wallpaper.sh` - Set random wallpaper

Make sure `dmenu` is installed for the menu scripts to work:

```bash
yay -S dmenu
```

## Keybindings

### Application Launchers
- `Super + b` - Open browser (Firefox)
- `Super + e` - Open file manager (Thunar)
- `Super + v` - Open code editor (Cursor)
- `Super + Alt + b` - Open Bluetooth manager

### System Control
- `Super + Shift + x` - Logout menu
- `Super + Shift + l` - Lock screen
- `Super + Shift + Escape` - Reload sxhkd config
- `Super + Alt + m` - Mount device menu
- `Super + Alt + u` - Unmount device menu

### Screenshots
- `Super + p` - Full screenshot
- `Super + Shift + p` - Interactive screenshot
- `Super + Alt + p` - Screenshot to clipboard

### Media Controls
- `XF86AudioMute` / `Alt + m` - Toggle mute
- `XF86AudioRaiseVolume` / `Alt + k` - Increase volume
- `XF86AudioLowerVolume` / `Alt + j` - Decrease volume
- `XF86AudioPlay` / `Alt + p` - Play/pause media
- `XF86AudioNext` / `Alt + l` - Next track
- `XF86AudioPrev` / `Alt + h` - Previous track

### Brightness
- `XF86MonBrightnessUp` / `Alt + Shift + k` - Increase brightness
- `XF86MonBrightnessDown` / `Alt + Shift + j` - Decrease brightness

> **Note**: dwm has its own keybindings for window management. Refer to your dwm config for those.

## Configuration

All configuration files are symlinked to `~/.config/` from the `dotconfig/` directory. You can edit them directly:

- `~/.config/sxhkd/sxhkdrc` - Hotkey bindings
- `~/.config/alacritty/` - Terminal configuration (if you create one)
- `~/.config/picom/picom.conf` - Compositor settings
- `~/.config/dunst/dunst.conf` - Notification daemon
- `~/.config/tmux/tmux.conf` - Terminal multiplexer
- `~/.config/neofetch/config.conf` - System info display

After editing configs:
- sxhkd: Press `Super + Shift + Escape` to reload
- picom: Restart with `pkill picom && picom &`
- dunst: Restart with `pkill dunst && dunst &`

## Project Structure

```
Antar-dwm/
├── install.sh              # Main installation script
├── dotconfig/              # Configuration files
│   ├── autostart.sh       # Session startup script
│   ├── sxhkd/             # Hotkey daemon config
│   ├── ...                # Config files
│   ├── picom/             # Compositor config
│   ├── dunst/             # Notification daemon
│   ├── tmux/              # Terminal multiplexer
│   └── ...
├── Source/                 # (DEPRECATED - will be removed)
│   └── ...                # Assets are now installed via packages
└── scripts/               # Helper scripts
    ├── logout.sh
    ├── mountmenu.sh
    ├── umountmenu.sh
    └── wallpaper.sh
```

## Customization

### Changing Themes

Themes and icons are installed via packages. You can change them using:

```bash
lxappearance  # GUI tool for GTK themes
# Or manually edit ~/.gtkrc-2.0 and ~/.config/gtk-3.0/settings.ini
```

**Installed themes include:**
- Catppuccin (Mocha, Frappe variants)
- Gruvbox Dark
- Tela Circle Icons (Dracula, Standard variants)
- Bibata Cursor Theme

**To install additional themes:**
```bash
yay -S <theme-package-name>
```

**Popular theme packages:**
- `catppuccin-gtk-theme-mocha` - Catppuccin Mocha theme
- `gruvbox-dark-gtk-theme-git` - Gruvbox theme
- `tela-circle-icon-theme-dracula` - Tela Circle Dracula icons
- `bibata-cursor-theme` - Bibata cursor theme

### Adding Packages

Edit `install.sh` and add packages to the appropriate variable (`app_pkgs`, `app_pkgs2`, etc.).

### Modifying Keybindings

Edit `~/.config/sxhkd/sxhkdrc` and reload with `Super + Shift + Escape`.

## Troubleshooting

### Installation Fails

- Check `install.log` for detailed error messages
- Ensure you have internet connectivity
- Verify you're running Arch Linux
- Make sure you have sufficient disk space

### Display Manager Issues

If dwm doesn't appear in your display manager:

1. Ensure `dotconfig/dwm.desktop` is copied to `/usr/share/xsessions/`:
   ```bash
   sudo cp dotconfig/dwm.desktop /usr/share/xsessions/
   ```

2. Restart your display manager:
   ```bash
   sudo systemctl restart ly  # or sddm, gdm, etc.
   ```

### Fonts Not Loading

Run font cache update:
```bash
fc-cache -vf
```

### Compositor Not Working

Check if picom is running:
```bash
pgrep picom
```

If not, start it manually:
```bash
picom &
```

Check logs for errors:
```bash
picom --log-level DEBUG
```

## Security Note

The installation script sets up `doas.conf` with `permit persist` for the current user. This allows passwordless sudo access after the first authentication. Review and adjust `/etc/doas.conf` according to your security requirements.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

See [LICENSE](LICENSE) file for details.

## Acknowledgments

- [dwm](https://dwm.suckless.org/) - Dynamic Window Manager
- [suckless tools](https://suckless.org/) - Minimalist software
- All the theme and icon creators whose work is included

## Package-Based Installation

This project now uses **package-based installation** instead of bundling assets. All fonts, themes, and icons are installed via Arch Linux packages and AUR, making the repository smaller and easier to maintain.

**Benefits:**
- ✅ Smaller repository size
- ✅ Automatic updates via package manager
- ✅ No need to manually update bundled assets
- ✅ Easy to add/remove themes and fonts

See [PACKAGES.md](PACKAGES.md) for a complete list of installed packages.

## Removing Source Folder

The `Source/` folder is no longer needed and can be safely deleted:

```bash
rm -rf Source/
```

All assets are now installed via packages during the installation process.

## Status

✅ **Ready for use** - This project has been cleaned up and uses package-based installation.

---

**Enjoy your new dwm setup!** 🎉
