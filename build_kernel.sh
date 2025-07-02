#!/bin/bash
set -e

# Assisted patch designed and tested specifically for:
#   - KernelSU-Next version 1.0.8
#   - susfs version 1.5.8
#
# Using different or newer versions of these components
# may cause unexpected behavior or errors.

# -----------------------------------------------------------------
# Note: This script may appear somewhat complex and cluttered.
# I have done my best to make the patching and kernel build process
# as simple and straightforward as possible.
# -----------------------------------------------------------------

if [[ -t 1 && -z $NO_COLOR ]]; then
  C_RESET="\e[0m";   C_BOLD="\e[1m"
  C_BLUE="\e[34m";   C_GREEN="\e[32m"
  C_YELLOW="\e[33m"; C_RED="\e[31m"
else
  C_RESET=""; C_BOLD=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""
fi

bold()    { printf "${C_BOLD}%s${C_RESET}\n" "$*"; }
header()  { printf "${C_BOLD}${C_BLUE}==> %s${C_RESET}\n" "$*"; }
step()    { printf "${C_BLUE} → %s${C_RESET}\n" "$*"; }
success() { printf "${C_GREEN} ✔ %s${C_RESET}\n" "$*"; }
warn()    { printf "${C_YELLOW} ! %s${C_RESET}\n" "$*"; }
error()   { printf "${C_RED} ✖ %s${C_RESET}\n" "$*"; }

CURRENT_PATH="$(pwd)"
TOOLCHAIN=$(realpath "prebuilts")
KERNEL_DIR=$(realpath "kernel-6.6")
SUSFS_DIR=$(realpath "susfs4ksu")
SAMFIX_DIR=$(realpath "samsung_fix")
WILD_DIR=$(realpath "wild_kernelpatches")
OUT_DIR=$(realpath "out")
MAGISKBOOT_DIR=$(realpath "magiskboot")

# -----------------------------------------------------------------
#  Defaults and Spoof variables (Change for different Firmware)   #
# -----------------------------------------------------------------
DEFAULT_INSTALL_KSU=1
DEFAULT_SPOOF=1
DEFAULT_BT_FIX=1
DEFAULT_DISABLE_PROTECTION=1

# Spoof strings: can be overridden by CLI options
SPOOF_LOCALVERSION="-abA566BXXS4AYE5-4k"
SPOOF_TIMESTAMP="Wed May 21 07:41:04 UTC 2025"

# -----------------------------------------------------------------
#  CLI flags                                                     #
# -----------------------------------------------------------------
while [[ $1 == --* ]]; do
  case $1 in
    --ksu)          shift; INSTALL_KSU=$1 ;;
    --spoof)        shift; SPOOF=$1 ;;
    --btfix)        shift; BT_FIX=$1 ;;
    --protection)   shift; DISABLE_PROTECTION=$1 ;;
    --localversion) shift; SPOOF_LOCALVERSION=$1 ;;
    --timestamp)    shift; SPOOF_TIMESTAMP=$1 ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

TARGET_DEFCONFIG=${1:-a56_defconfig}

# -----------------------------------------------------------------
#  Ask function                                                   #
# -----------------------------------------------------------------
ask_function() {
  local question="$1"
  local default="$2"
  local reply tries=2
  local prompt="[1=Yes / 0=No] (default=${default})"
  while (( tries >= 0 )); do
    printf "${C_BOLD}${C_YELLOW}* %s %s ${C_RESET}" "$question" "$prompt"
    read -r reply
    [[ -z $reply ]] && reply=$default
    case $reply in
      1) return 0 ;;  # yes
      0) return 1 ;;  # no
      *) error "Please enter 1 (Yes) or 0 (No)."; ((tries--));;
    esac
  done
  return 1  # fallback no
}

# -----------------------------------------------------------------
#  Check required directories                                     #
# -----------------------------------------------------------------
if [[ ! -d "$TOOLCHAIN" ]]; then
  error "Toolchain directory not found: $TOOLCHAIN"
  exit 1
fi
if [[ ! -d "$KERNEL_DIR" ]]; then
  error "Kernel source directory not found: $KERNEL_DIR"
  exit 1
fi

# -----------------------------------------------------------------
#  Setup toolchain environment                                    #
# -----------------------------------------------------------------
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

ARGS="CC=clang ARCH=arm64 LLVM=1 LLVM_IAS=1"

# -----------------------------------------------------------------
#  Kernel configuration                                           #
# -----------------------------------------------------------------
make -j"$(nproc)" -C "$KERNEL_DIR" O="$OUT_DIR" ${ARGS} "$TARGET_DEFCONFIG"
[[ -f "$OUT_DIR/.config" ]] || { error ".config not found."; exit 1; }

# -----------------------------------------------------------------
#  Assisted patch question                                        #
# -----------------------------------------------------------------
if [[ -t 0 ]]; then
  bold "Kernel Build Script"
  if ask_function "Do you want to apply the assisted patch before compiling?" 0; then
    DO_PATCH=true
  else
    DO_PATCH=false
  fi
else
  # Non-interactive fallback:
  DO_PATCH=true
fi

# -----------------------------------------------------------------
#  Apply patches                                                  #
# -----------------------------------------------------------------
if $DO_PATCH; then
  DO_INSTALL_KSU=false
  DO_INTEGRATE_SUSFS=false

  if [[ ! -d "$KERNEL_DIR/KernelSU-Next" ]]; then
    if [[ $INSTALL_KSU == 1 ]]; then
      DO_INSTALL_KSU=true
    elif [[ $INSTALL_KSU == 0 ]]; then
      DO_INSTALL_KSU=false
    elif [[ -t 0 ]]; then
      bold "KernelSU-Next v1.0.8"
      if ask_function "Install KernelSU-Next?" "$DEFAULT_INSTALL_KSU"; then
        DO_INSTALL_KSU=true
      else
        DO_INSTALL_KSU=false
      fi
    else
      warn "Skipping KernelSU-Next (set --ksu 1 for auto-install)."
      DO_INSTALL_KSU=false
    fi

    if $DO_INSTALL_KSU; then
      step "Installing KernelSU-Next v1.0.8..."
      (
        cd "$KERNEL_DIR" || exit 1
        curl -LSs https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh | bash -s v1.0.8
      )

      # Check if susfs4ksu & wild_kernelpatches folder exists
      if [[ -d "$SUSFS_DIR" && $(ls -A "$SUSFS_DIR") && -d "$WILD_DIR" && $(ls -A "$WILD_DIR") ]]; then
        if ask_function "Integrate susfs for android15-6-6?" 1; then
          DO_INTEGRATE_SUSFS=true
          (
            warn "Warning: If unexpected behavior arises, please await an update or apply a manual fix."
            cd "$KERNEL_DIR" || { error "Failed to enter kernel directory: $KERNEL_DIR"; exit 1; }
            cp -r "$SUSFS_DIR/kernel_patches/fs/"* "$KERNEL_DIR/fs/" || error "Failed to copy fs/ directory"
            cp -r "$SUSFS_DIR/kernel_patches/include/"* "$KERNEL_DIR/include/" || error "Failed to copy include/ directory"
            patch -p1 < "$SUSFS_DIR/kernel_patches/50_add_susfs_in_gki-android15-6.6.patch"
            (
              cd "$KERNEL_DIR/KernelSU-Next" || { error "Failed to enter KernelSU-Next directory: $KERNEL_DIR/KernelSU-Next"; exit 1; }
              patch -p1 < "$WILD_DIR/next/0001-kernel-implement-susfs-v1.5.8-KernelSU-Next-v1.0.8.patch" || true # Ignore error because fix get applied
            ) && success "KernelSU-Next susfs patch applied successfully." || error "Failed to apply KernelSU-Next susfs patch."
              patch -p1 < "$WILD_DIR/next/scope_min_manual_hooks_v1.4.patch" || true # Ignore error because fix get applied
              # -----------------------------------------------------------------
              #  Samsung Hotfix                                                 #
              # -----------------------------------------------------------------
              if [[ -d "$SAMFIX_DIR" && $(ls -A "$SAMFIX_DIR") ]]; then
                bold "Apply Samsung susfs hotfix..."
                patch -p1 < "$SAMFIX_DIR/namespace.patch"
                patch -p1 < "$SAMFIX_DIR/open.patch"
              fi
              # -----------------------------------------------------------------
              #  susfs + KernelSU‑Next recommend config                         #
              # -----------------------------------------------------------------
              step "Applying susfs / KSU config symbol"
              "$KERNEL_DIR/scripts/config" --file "$OUT_DIR/.config" \
                -e CONFIG_KSU \
                -d CONFIG_KSU_KPROBES_HOOK \
                -e CONFIG_KSU_SUSFS \
                -e CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT \
                -e CONFIG_KSU_SUSFS_SUS_PATH \
                -e CONFIG_KSU_SUSFS_SUS_MOUNT \
                -e CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT \
                -e CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT \
                -e CONFIG_KSU_SUSFS_SUS_KSTAT \
                -d CONFIG_KSU_SUSFS_SUS_OVERLAYFS \
                -e CONFIG_KSU_SUSFS_TRY_UMOUNT \
                -e CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT \
                -e CONFIG_KSU_SUSFS_SPOOF_UNAME \
                -e CONFIG_KSU_SUSFS_ENABLE_LOG \
                -e CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
                -e CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG \
                -e CONFIG_KSU_SUSFS_OPEN_REDIRECT \
                -d CONFIG_KSU_SUSFS_SUS_SU
          ) && success "Kernel susfs patch applied successfully." || error "Failed to apply Kernel susfs patch."
        else
          warn "susfs will not be integrated."
        fi
      fi
    else
      warn "KernelSU-Next will not be installed."x
    fi
  fi
fi

# -----------------------------------------------------------------
#  Spoof localversion and build timestamp                        #
# -----------------------------------------------------------------
if $DO_PATCH; then
  if [[ $SPOOF != 0 ]]; then
    if [[ $SPOOF == 1 ]]; then
      DO_SPOOF=true
    elif [[ -t 0 ]]; then
      if ask_function "Spoof LOCALVERSION and build timestamp?" "$DEFAULT_SPOOF"; then
        DO_SPOOF=true
      else
        DO_SPOOF=false
      fi
    else
      DO_SPOOF=$DEFAULT_SPOOF
    fi
  else
    DO_SPOOF=false
  fi

  if $DO_SPOOF; then
    step "Applying spoof: LOCALVERSION='${SPOOF_LOCALVERSION}', timestamp='${SPOOF_TIMESTAMP}' ..."
    sed -i "s|^CONFIG_LOCALVERSION=.*|CONFIG_LOCALVERSION=\"${SPOOF_LOCALVERSION}\"|" \
      "$KERNEL_DIR/arch/arm64/configs/$TARGET_DEFCONFIG"
    sed -i "s|build-timestamp = .*|build-timestamp = \"${SPOOF_TIMESTAMP}\"|" \
      "$KERNEL_DIR/init/Makefile"
  fi
fi

# -----------------------------------------------------------------
#  Bluetooth fixes | Thanks to @ReeViiS69 for this fix            #
# -----------------------------------------------------------------
if $DO_PATCH; then
  if [[ $BT_FIX != 0 ]]; then
    if [[ $BT_FIX == 1 ]]; then
      DO_BTFIX=true
    elif [[ -t 0 ]]; then
      if ask_function "Apply Bluetooth fix?" "$DEFAULT_BT_FIX"; then
        DO_BTFIX=true
      else
        DO_BTFIX=false
      fi
    else
      DO_BTFIX=$DEFAULT_BT_FIX
    fi
  else
    DO_BTFIX=false
  fi

  if $DO_BTFIX; then
    step "Applying Bluetooth fixes..."
    "$KERNEL_DIR/scripts/config" --file "$OUT_DIR/.config" \
      -e CONFIG_BT \
      -e CONFIG_BT_BREDR \
      -e CONFIG_BT_RFCOMM \
      -e CONFIG_BT_RFCOMM_TTY \
      -e CONFIG_BT_HIDP \
      -e CONFIG_BT_LE \
      -e CONFIG_BT_DEBUGFS \
      -e CONFIG_BT_BCM \
      -e CONFIG_BT_QCA \
      -e CONFIG_BT_HCIBTSDIO \
      -e CONFIG_BT_HCIUART \
      -e CONFIG_BT_HCIUART_SERDEV \
      -e CONFIG_BT_HCIUART_H4 \
      -e CONFIG_BT_HCIUART_LL \
      -e CONFIG_BT_HCIUART_BCM \
      -e CONFIG_BT_HCIUART_QCA \
      -e CONFIG_FIB_RULES \
      -e CONFIG_WIRELESS \
      -e CONFIG_WIRELESS_EXT \
      -e CONFIG_WEXT_CORE \
      -e CONFIG_WEXT_PROC \
      -e CONFIG_WEXT_SPY \
      -e CONFIG_WEXT_PRIV \
      -m CONFIG_CFG80211 \
      -e CONFIG_NL80211_TESTMODE \
      -e CONFIG_CFG80211_REQUIRE_SIGNED_REGDB \
      -e CONFIG_CFG80211_USE_KERNEL_REGDB_KEYS \
      -e CONFIG_CFG80211_DEFAULT_PS \
      -e CONFIG_CFG80211_CRDA_SUPPORT \
      -m CONFIG_MAC80211 \
      -e CONFIG_MAC80211_HAS_RC \
      -e CONFIG_MAC80211_RC_MINSTREL \
      -e CONFIG_MAC80211_RC_DEFAULT_MINSTREL \
      --set-str CONFIG_MAC80211_RC_DEFAULT "minstrel_ht" \
      --set-val CONFIG_MAC80211_STA_HASH_MAX_SIZE 0 \
      -e CONFIG_RFKILL \
      -e CONFIG_RFKILL_LEDS \
      -e CONFIG_NFC \
      -m CONFIG_SAMSUNG_NFC \
      -e CONFIG_NFC_PVDD_LATE_ENABLE \
      -e CONFIG_SEC_NFC_LOGGER \
      --set-val CONFIG_SEC_NFC_WAKELOCK_METHOD 0 \
      -e CONFIG_NFC_PN547 \
      -e CONFIG_NFC_FEATURE_SN100U \
      -e CONFIG_SEC_NFC_COMPAT_IOCTL \
      -e CONFIG_DST_CACHE \
      -e CONFIG_GRO_CELLS \
      -e CONFIG_PAGE_POOL \
      -e CONFIG_ETHTOOL_NETLINK \
      -e CONFIG_HAVE_EBPF_JIT
  else
    warn "Bluetooth fix skipped."
  fi
fi

# -----------------------------------------------------------------
#  Disable Samsung kernel protection                             #
# -----------------------------------------------------------------
if $DO_PATCH; then
  if [[ $DISABLE_PROTECTION != 0 ]]; then
    if [[ $DISABLE_PROTECTION == 1 ]]; then
      DO_PROTECTION=true
    elif [[ -t 0 ]]; then
      if ask_function "Disable Samsung kernel protection?" "$DEFAULT_DISABLE_PROTECTION"; then
        DO_PROTECTION=true
      else
        DO_PROTECTION=false
      fi
    else
      DO_PROTECTION=$DEFAULT_DISABLE_PROTECTION
    fi
  else
    DO_PROTECTION=false
  fi

  if $DO_PROTECTION; then
    step "Disabling Samsung kernel protection..."
    "$KERNEL_DIR/scripts/config" --file "$OUT_DIR/.config" \
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
  else
    warn "Samsung protection left intact."
  fi
fi

# -----------------------------------------------------------------
#  Final build                                                    #
# -----------------------------------------------------------------
if $DO_PATCH; then
  make -C "$KERNEL_DIR" O="$OUT_DIR" ${ARGS} olddefconfig
fi

# ThinLTO
if [[ $LTO == "thin" ]]; then
  "$KERNEL_DIR/scripts/config" --file "$OUT_DIR/.config" -e LTO_CLANG_THIN -d LTO_CLANG_FULL
fi

make -j"$(nproc)" -C "$KERNEL_DIR" O="$OUT_DIR" ${ARGS}

# -----------------------------------------------------------------
#  Finish: copy Image and repack with MagiskBoot                 #
# -----------------------------------------------------------------
IMAGE_SRC="$OUT_DIR/arch/arm64/boot/Image"
[[ -f "$IMAGE_SRC" ]] || { error "Image not found. Build failed."; exit 1; }

MAGISKBOOT_KERNEL_DIR="$MAGISKBOOT_DIR/boot"
mkdir -p "$MAGISKBOOT_KERNEL_DIR"
cp "$IMAGE_SRC" "$MAGISKBOOT_KERNEL_DIR/kernel"
cd "$MAGISKBOOT_KERNEL_DIR"

[[ -f kernel ]] || { error "Kernel file missing in magiskboot directory."; exit 1; }
[[ -f ../boot.img ]] || { error "boot.img not found in magiskboot directory."; exit 1; }
[[ -f ../certificate.pem ]] || { error "certificate.pem not found in magiskboot directory."; exit 1; }

../magiskboot repack ../boot.img "$CURRENT_PATH/boot.img"
../magiskboot sign ../certificate.pem "$CURRENT_PATH/boot.img"

success "Build complete! Signed boot image created at: $CURRENT_PATH/boot.img"
