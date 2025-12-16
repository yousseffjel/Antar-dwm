#!/usr/bin/env bash
# Unmount menu script
# Provides a dmenu interface to unmount devices

# Detect privilege escalation command
if command -v doas &> /dev/null; then
    SUDO_CMD="doas"
elif command -v sudo &> /dev/null; then
    SUDO_CMD="sudo"
else
    notify-send "Unmount" "Neither sudo nor doas found. Please install one."
    exit 1
fi

# Get list of mounted block devices (excluding root and system mounts)
MOUNTS=$(lsblk -rno NAME,MOUNTPOINT | awk '$2!="" && $2!="/" && $2!="/boot" && $2!="/home" {print $2 " (" $1 ")"}')

if [ -z "$MOUNTS" ]; then
    notify-send "Unmount" "No mounted devices found"
    exit 0
fi

# Show menu and get selection
SELECTED=$(echo "$MOUNTS" | dmenu -i -p "Unmount device:")

if [ -n "$SELECTED" ]; then
    # Extract mount point (before the space)
    MOUNTPOINT=$(echo "$SELECTED" | awk '{print $1}')
    
    # SECURITY: Validate mount point against actual mounted filesystems
    # This prevents unmounting unintended filesystems
    if [ -z "$MOUNTPOINT" ]; then
        notify-send "Unmount" "Invalid selection"
        exit 1
    fi
    
    # Verify mount point exists in the original list (defense in depth)
    if ! echo "$MOUNTS" | grep -q "^${MOUNTPOINT}"; then
        notify-send "Unmount" "Mount point not found in mounted devices list"
        exit 1
    fi
    
    # Additional validation: check if mount point is actually mounted
    if ! mountpoint -q "$MOUNTPOINT" 2>/dev/null; then
        notify-send "Unmount" "Mount point is not currently mounted: $MOUNTPOINT"
        exit 1
    fi
    
    # Try to unmount (capture error output for better diagnostics)
    UMOUNT_ERROR=$($SUDO_CMD umount "$MOUNTPOINT" 2>&1)
    if [ $? -eq 0 ]; then
        notify-send "Unmount" "Unmounted $MOUNTPOINT"
        # Clean up mount point directory if it's in user's mnt directory
        if [ -d "$MOUNTPOINT" ] && [ "$(dirname "$MOUNTPOINT")" = "$HOME/mnt" ]; then
            rmdir "$MOUNTPOINT" 2>/dev/null || true
        fi
    else
        # Show error message if available, otherwise generic message
        if [ -n "$UMOUNT_ERROR" ]; then
            notify-send "Unmount" "Failed to unmount $MOUNTPOINT: ${UMOUNT_ERROR:0:100}"
        else
            notify-send "Unmount" "Failed to unmount $MOUNTPOINT"
        fi
    fi
fi

