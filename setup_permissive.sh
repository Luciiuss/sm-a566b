#!/bin/bash
set -e

[[ -d permissive ]] || { echo "Missing SELinux permissive fixes!"; exit 1; }

echo "Copy permissive.patch..."
cp permissive/permissive.patch $(dirname "$0")/kernel-6.6

cd "$(dirname "$0")/kernel-6.6"
echo "Patching SELinux permissive patch..."
patch -p1 < permissive.patch

echo "SELinux permissive patch successfully installed."
echo "Make sure you enable CONFIG_SECURITY_SELINUX_DEVELOP before you compile!"
