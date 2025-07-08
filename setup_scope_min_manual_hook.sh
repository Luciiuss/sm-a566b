#!/bin/bash
set -e

# Tested version: 1.4

[ -d kernel_patches ] || git clone https://github.com/WildKernels/kernel_patches.git

echo "Copy scope_min_manual_hooks_v1.4.patch to kernel source..."
cp -r kernel_patches/next/scope_min_manual_hooks_v1.4.patch $(dirname "$0")/kernel-6.6

# Samsung Fix
echo "Copy open.patch..."
cp samsung_fix/open.patch $(dirname "$0")/kernel-6.6

cd "$(dirname "$0")/kernel-6.6"
echo "Patching scope_min_manual_hooks..."
patch -p1 < scope_min_manual_hooks_v1.4.patch  || true # Ignore patch errors
echo "Patching Samsung fix..."
patch -p1 < open.patch

echo "scope_min_manual_hooks successfully installed."
