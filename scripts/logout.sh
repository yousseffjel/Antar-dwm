#!/bin/bash
# Logout script for dwm
# This script provides a menu to logout, reboot, or shutdown

CHOICE=$(echo -e "Logout\nReboot\nShutdown\nCancel" | dmenu -i -p "Session:")

case "$CHOICE" in
    Logout)
        pkill -TERM dwm || pkill -TERM X
        ;;
    Reboot)
        systemctl reboot
        ;;
    Shutdown)
        systemctl poweroff
        ;;
    Cancel)
        exit 0
        ;;
esac

