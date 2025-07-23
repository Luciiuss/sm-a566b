#!/bin/bash
set -e

###############################################################################
# - Kernel sources:   <script dir>/kernel-6.6
# - Prebuilts/toolchain: <script dir>/prebuilts
###############################################################################

# Change to your actual firmware version to match the stock kernel string.
VERSION="LUCIUS"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="${SCRIPT_DIR}/kernel-6.6"

NEXT_DIR="${KERNEL_DIR}/KernelSU-Next"
SUSFS_FILE="${KERNEL_DIR}/fs/susfs.c"

TOOLCHAIN="${SCRIPT_DIR}/prebuilts"

if [ ! -d "$TOOLCHAIN" ]; then
    echo "ERROR: Missing toolchain"
    exit 1
fi

export PATH="${TOOLCHAIN}/build-tools/linux-x86/bin:${PATH}"
export PATH="${TOOLCHAIN}/build-tools/path/linux-x86:${PATH}"
export PATH="${TOOLCHAIN}/clang/host/linux-x86/clang-r510928/bin:${PATH}"
export PATH="${TOOLCHAIN}/kernel-build-tools/linux-x86/bin:${PATH}"

LLD_COMPILER_RT="-fuse-ld=lld --rtlib=compiler-rt"
SYSROOT_FLAGS="--sysroot=${TOOLCHAIN}/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/sysroot"

CFLAGS="-I${TOOLCHAIN}/kernel-build-tools/linux-x86/include "
LDFLAGS="-L${TOOLCHAIN}/kernel-build-tools/linux-x86/lib64 ${LLD_COMPILER_RT}"

export LD_LIBRARY_PATH="${TOOLCHAIN}/kernel-build-tools/linux-x86/lib64"
export HOSTCFLAGS="${SYSROOT_FLAGS} ${CFLAGS}"
export HOSTLDFLAGS="${SYSROOT_FLAGS} ${LDFLAGS}"

# defconfig
TARGET_DEFCONFIG="${1:-a56_defconfig}"
ARGS="CC=clang ARCH=arm64 LLVM=1 LLVM_IAS=1"

make -j"$(nproc)" \
     -C "${KERNEL_DIR}" \
     O="${KERNEL_DIR}/out" \
     ${ARGS} \
     "${TARGET_DEFCONFIG}"

CONFIG_FILE="${KERNEL_DIR}/out/.config"
if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "ERROR: .config not found at ${CONFIG_FILE}"
  exit 1
fi

# Disable Samsung Protection
"${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" \
  -d UH -d RKP -d KDP -d SECURITY_DEFEX -d INTEGRITY -d FIVE \
  -d TRIM_UNUSED_KSYMS -d PROCA -d PROCA_GKI_10 -d PROCA_S_OS \
  -d PROCA_CERTIFICATES_XATTR -d PROCA_CERT_ENG -d PROCA_CERT_USER \
  -d GAF -d GAF_V6 -d FIVE_CERT_USER -d FIVE_DEFAULT_HASH

# Change LOCALVERSION
"${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" \
  --set-str CONFIG_LOCALVERSION "-$VERSION-4k"

# Add additional tmpfs settings
"${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" \
  -e CONFIG_TMPFS_XATTR -e CONFIG_TMPFS_POSIX_ACL

# KernelSU-Next config
if [ -d "$NEXT_DIR" ]; then
"${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" \
  -e CONFIG_KSU -d CONFIG_KSU_KPROBES_HOOK
fi

# SUSFS config
if [ "$SUSFS_FILE" ]; then
"${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" \
  -e CONFIG_KSU_SUSFS -e CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT \
  -e CONFIG_KSU_SUSFS_SUS_PATH -e CONFIG_KSU_SUSFS_SUS_MOUNT \
  -e CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT \
  -e CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT \
  -e CONFIG_KSU_SUSFS_SUS_KSTAT -d CONFIG_KSU_SUSFS_SUS_OVERLAYFS \
  -e CONFIG_KSU_SUSFS_TRY_UMOUNT \
  -e CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT \
  -e CONFIG_KSU_SUSFS_SPOOF_UNAME -e CONFIG_KSU_SUSFS_ENABLE_LOG \
  -e CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
  -e CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG \
  -e CONFIG_KSU_SUSFS_OPEN_REDIRECT -d CONFIG_KSU_SUSFS_SUS_SU
fi

# Thin‑LTO
if [[ "${LTO:-}" == "thin" ]]; then
  "${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" \
    -e LTO_CLANG_THIN -d LTO_CLANG_FULL
fi

# Compile
make -j"$(nproc)" \
     -C "${KERNEL_DIR}" \
     O="${KERNEL_DIR}/out" \
     ${ARGS}

echo "✔ Kernel build finished."
