#!/bin/sh

# NOTE: Processes are started in the background with &, so we can't easily check
# their exit status. The `command -v` checks ensure commands exist before starting.
# If a process fails after startup, it will fail silently. For debugging,
# check system logs or process status manually.

# Update D-Bus environment for systemd
dbus-update-activation-environment --systemd DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY &

# Start polkit authentication agent
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Merge X resources if file exists
[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources" &

# Start status bar (if slstatus is installed)
command -v slstatus >/dev/null 2>&1 && slstatus &

# Start compositor
command -v picom >/dev/null 2>&1 && picom &

# Set wallpaper (use custom script if available, otherwise use feh)
if [ -f "$HOME/src/bin/wallpaper.sh" ]; then
    "$HOME/src/bin/wallpaper.sh" &
elif command -v feh >/dev/null 2>&1 && [ -d "$HOME/Pictures/Wallpapers" ]; then
    feh --bg-fill "$HOME/Pictures/Wallpapers"/* 2>/dev/null &
fi

# Start hotkey daemon
command -v sxhkd >/dev/null 2>&1 && sxhkd -c "$HOME/.config/sxhkd/sxhkdrc" &

# Start system tray applets
command -v blueman-applet >/dev/null 2>&1 && blueman-applet &
command -v nm-applet >/dev/null 2>&1 && nm-applet --indicator &
command -v copyq >/dev/null 2>&1 && copyq &

# Start notification daemon
command -v dunst >/dev/null 2>&1 && dunst &

# Note: satty doesn't need a daemon, it's called on-demand via keybindings
