#!/bin/bash

# Script to create a swap file on Ubuntu 22.04
# Usage: sudo ./swap.sh <size_in_GB>, e.g., sudo ./swap.sh 32

# Check if an argument was provided
if [ $# -ne 1 ]; then
    echo "Error: Specify the size in GB. Example: sudo ./swap.sh 32"
    exit 1
fi

# Verify that the argument is a positive integer
if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -le 0 ]; then
    echo "Error: Enter a positive integer for the size in GB."
    exit 1
fi

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)."
    exit 1
fi

# Variables
SIZE=$1  # Size in GB
SWAP_FILE="/swap.img"
BLOCK_SIZE=1M
COUNT=$((SIZE * 1024))  # Convert GB to MB (1 GB = 1024 MB)

# Check available disk space
AVAILABLE_SPACE=$(df -m / | tail -1 | awk '{print $4}')  # Available space in MB
if [ "$AVAILABLE_SPACE" -lt "$COUNT" ]; then
    echo "Error: Insufficient disk space. Required: ${SIZE}GB (${COUNT}MB), Available: ${AVAILABLE_SPACE}MB."
    exit 1
fi

# Disable existing swap
echo "Disabling current swap..."
swapoff "$SWAP_FILE" 2>/dev/null || echo "No active swap to disable."

# Remove the old swap file (if it exists)
if [ -f "$SWAP_FILE" ]; then
    echo "Removing the old swap file..."
    rm -f "$SWAP_FILE"
fi

# Create a new swap file
echo "Creating a new swap file of ${SIZE}GB..."
dd if=/dev/zero of="$SWAP_FILE" bs="$BLOCK_SIZE" count="$COUNT" status=progress

# Set correct permissions
echo "Setting permissions..."
chmod 600 "$SWAP_FILE"

# Format the file as swap
echo "Formatting the file as swap..."
mkswap "$SWAP_FILE"

# Enable the new swap
echo "Enabling the new swap..."
swapon "$SWAP_FILE"

# Verify the result
echo "Verifying active swap:"
swapon --show

# Check if the file is already in /etc/fstab; if not, add it
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "Adding $SWAP_FILE to /etc/fstab for persistence on reboot..."
    echo "$SWAP_FILE none swap sw 0 0" | tee -a /etc/fstab
else
    echo "$SWAP_FILE already present in /etc/fstab."
fi

echo "Swap of ${SIZE}GB created and enabled successfully!"
