#!/usr/bin/env bash
# Mount menu script
# Provides a dmenu interface to mount devices

# Detect privilege escalation command
if command -v doas &> /dev/null; then
    SUDO_CMD="doas"
elif command -v sudo &> /dev/null; then
    SUDO_CMD="sudo"
else
    notify-send "Mount" "Neither sudo nor doas found. Please install one."
    exit 1
fi

# Get list of unmounted block devices
DEVICES=$(lsblk -rno NAME,TYPE,MOUNTPOINT | awk '$2=="part" && $3=="" {print $1}')

if [ -z "$DEVICES" ]; then
    notify-send "Mount" "No unmounted devices found"
    exit 0
fi

# Show menu and get selection
SELECTED=$(echo "$DEVICES" | dmenu -i -p "Mount device:")

if [ -n "$SELECTED" ]; then
    # SECURITY: Validate device name to prevent path traversal attacks
    # Only allow alphanumeric characters, hyphens, and underscores
    if ! echo "$SELECTED" | grep -qE '^[a-zA-Z0-9_-]+$'; then
        notify-send "Mount" "Invalid device name: $SELECTED"
        exit 1
    fi
    
    # Verify device exists in the original list (defense in depth)
    if ! echo "$DEVICES" | grep -q "^${SELECTED}$"; then
        notify-send "Mount" "Device not found in available devices list"
        exit 1
    fi
    
    DEVICE="/dev/$SELECTED"
    MOUNTPOINT="$HOME/mnt/$SELECTED"
    
    # Create mount point if it doesn't exist
    if ! mkdir -p "$MOUNTPOINT"; then
        notify-send "Mount" "Failed to create mount point: $MOUNTPOINT"
        exit 1
    fi
    
    # Try to mount (capture error output for better diagnostics)
    MOUNT_ERROR=$($SUDO_CMD mount "$DEVICE" "$MOUNTPOINT" 2>&1)
    if [ $? -eq 0 ]; then
        notify-send "Mount" "Mounted $DEVICE to $MOUNTPOINT"
        thunar "$MOUNTPOINT" &
    else
        # Show error message if available, otherwise generic message
        if [ -n "$MOUNT_ERROR" ]; then
            notify-send "Mount" "Failed to mount $DEVICE: ${MOUNT_ERROR:0:100}"
        else
            notify-send "Mount" "Failed to mount $DEVICE"
        fi
        # Clean up mount point if mount failed
        rmdir "$MOUNTPOINT" 2>/dev/null || true
    fi
fi

