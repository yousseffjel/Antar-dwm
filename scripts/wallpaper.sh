#!/usr/bin/env bash
# Wallpaper script
# Sets a random wallpaper from the wallpapers directory

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Fallback to alternative location
if [ ! -d "$WALLPAPER_DIR" ]; then
    WALLPAPER_DIR="$HOME/.local/share/wallpapers"
fi

# Check if directory exists and has images
if [ -d "$WALLPAPER_DIR" ]; then
    # Get random image file (use shuf if available, otherwise use sort -R)
    if command -v shuf >/dev/null 2>&1; then
        if ! WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) 2>/dev/null | shuf -n 1); then
            # find command failed, exit silently
            exit 0
        fi
    else
        if ! WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) 2>/dev/null | sort -R | head -n 1); then
            # find command failed, exit silently
            exit 0
        fi
    fi
    
    if [ -n "$WALLPAPER" ]; then
        # Use feh to set wallpaper
        if command -v feh >/dev/null 2>&1; then
            feh --bg-fill "$WALLPAPER"
        fi
    fi
fi

