#!/bin/bash
set -e

# My simple build script for those who prefer to keep things
# Please run this inside the "kernel-6.6" directory.

TOOLCHAIN=$(realpath "../prebuilts")

export PATH=$TOOLCHAIN/build-tools/linux-x86/bin:$PATH
export PATH=$TOOLCHAIN/build-tools/path/linux-x86:$PATH
export PATH=$TOOLCHAIN/clang/host/linux-x86/clang-r510928/bin:$PATH
export PATH=$TOOLCHAIN/kernel-build-tools/linux-x86/bin:$PATH

LLD_COMPILER_RT="-fuse-ld=lld --rtlib=compiler-rt"

sysroot_flags+="--sysroot=$TOOLCHAIN/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/sysroot"

cflags+="-I$TOOLCHAIN/kernel-build-tools/linux-x86/include "
ldflags+="-L $TOOLCHAIN/kernel-build-tools/linux-x86/lib64 "
ldflags+=${LLD_COMPILER_RT}

export LD_LIBRARY_PATH="$TOOLCHAIN/kernel-build-tools/linux-x86/lib64"
export HOSTCFLAGS="$sysroot_flags $cflags"
export HOSTLDFLAGS="$sysroot_flags $ldflags"

TARGET_DEFCONFIG=${1:-a56_defconfig}

ARGS="CC=clang ARCH=arm64 LLVM=1 LLVM_IAS=1"

make -j$(nproc) -C $(pwd) O=$(pwd)/out ${ARGS} $TARGET_DEFCONFIG

if [ ! -f out/.config ]; then
  echo "ERROR: .config not found."
  exit 1
fi

# Disable Samsung Protection
./scripts/config --file out/.config \
  -d UH \
  -d RKP \
  -d KDP \
  -d SECURITY_DEFEX \
  -d INTEGRITY \
  -d FIVE \
  -d TRIM_UNUSED_KSYMS \
  -d PROCA \
  -d PROCA_GKI_10 \
  -d PROCA_S_OS \
  -d PROCA_CERTIFICATES_XATTR \
  -d PROCA_CERT_ENG \
  -d PROCA_CERT_USER \
  -d GAF \
  -d GAF_V6 \
  -d FIVE_CERT_USER \
  -d FIVE_DEFAULT_HASH

if [ "$LTO" = "thin" ]; then
  ./scripts/config --file out/.config -e LTO_CLANG_THIN -d LTO_CLANG_FULL
fi

# Compile
make -j$(nproc) -C $(pwd) O=$(pwd)/out ${ARGS}
