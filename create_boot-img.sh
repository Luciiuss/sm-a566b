#!/bin/bash
set -e

if [[ ! -f kernel-6.6/out/arch/arm64/boot/Image ]]; then
  echo "Missing kernel Image. Please compile your kernel first."
  exit 1
fi

if [[ ! -f magiskboot/boot.img ]]; then
  echo "boot.img not found in magiskboot folder.."
  exit 1
fi

if [[ ! -x magiskboot/magiskboot ]]; then
  echo "magiskboot executable is missing."
  exit 1
fi

mkdir -p magiskboot/boot
cp kernel-6.6/out/arch/arm64/boot/Image magiskboot/boot/kernel
echo "Kernel image copied."

cd magiskboot/boot
../magiskboot repack ../boot.img ../../boot.img
../magiskboot sign ../../boot.img ../certificate.pem
echo "boot.img repacked and signed."

cd ../..
tar -cf boot.img.tar boot.img
echo "Created boot.img.tar archive."
