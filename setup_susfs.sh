#!/bin/bash
set -e

# Tested susfs version: 1.5.9

[[ -d kernel-6.6/KernelSU-Next ]] || { echo "Please install KernelSU-Next before you install susfs!"; exit 1; }
[[ -d next_fix ]] || { echo "Missing KernelSU-Next fixes!"; exit 1; }
[[ -d samsung_fix ]] || { echo "Missing Samsung fixes!"; exit 1; }

[ -d susfs4ksu ] || git clone --depth=1 --branch gki-android15-6.6 https://gitlab.com/simonpunk/susfs4ksu.git
echo "Copy kernel_patches/fs to kernel source..."
cp -r susfs4ksu/kernel_patches/fs $(dirname "$0")/kernel-6.6
echo "Copy kernel_patches/include to kernel source..."
cp -r susfs4ksu/kernel_patches/include $(dirname "$0")/kernel-6.6
echo "Copy 50_add_susfs_in_gki-android15-6.6.patch..."
cp -r susfs4ksu/kernel_patches/50_add_susfs_in_gki-android15-6.6.patch $(dirname "$0")/kernel-6.6

echo "Copy 10_enable_susfs_for_ksu.patch..."
cp -r susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch $(dirname "$0")/kernel-6.6/KernelSU-Next

# Samsung Fix
echo "Copy namespace.patch..."
cp samsung_fix/namespace.patch $(dirname "$0")/kernel-6.6

# KernelSU-Next Fix
echo "Copy apk_sign.patch..."
cp next_fix/apk_sign.patch $(dirname "$0")/kernel-6.6/KernelSU-Next
echo "Copy core_hook.patch..."
cp next_fix/core_hook.patch $(dirname "$0")/kernel-6.6/KernelSU-Next
echo "Copy ksud.patch..."
cp next_fix/ksud.patch $(dirname "$0")/kernel-6.6/KernelSU-Next
echo "Copy selinux.patch..."
cp next_fix/selinux.patch $(dirname "$0")/kernel-6.6/KernelSU-Next
echo "Copy sucompat.patch..."
cp next_fix/sucompat.patch $(dirname "$0")/kernel-6.6/KernelSU-Next

cd "$(dirname "$0")/kernel-6.6"
echo "Patching kernel..."
patch -p1 < 50_add_susfs_in_gki-android15-6.6.patch || true # Ignore patch errors
echo "Patching Samsung fix..."
patch -p1 < namespace.patch

cd "$(dirname "$0")/KernelSU-Next"
echo "Patching KernelSU..."
patch -p1 < 10_enable_susfs_for_ksu.patch || true # Ignore patch errors
echo "Patching Kernel-Next fix..."
patch -p1 < apk_sign.patch
patch -p1 < core_hook.patch
patch -p1 < ksud.patch
patch -p1 < selinux.patch
patch -p1 < sucompat.patch

echo "susfs successfully installed."
