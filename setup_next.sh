#!/bin/bash
set -e

cd "$(dirname "$0")/kernel-6.6"

echo "KernelSU-Next dev branch? (y/n)"
read -r answer

if [[ "$answer" == "y" ]]; then
    echo "Installing KernelSU-Next dev..."
    curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s next
elif [[ "$answer" == "n" ]]; then
    echo "Installing KernelSU-Next stable..."
    curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -
else
    echo "Invalid"
    exit 1
fi
