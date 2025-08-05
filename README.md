# Samsung Galaxy A56 (SM‑A566B)

> ⚠️ **Toolchains are *not* included in this repository.** ⚠️
> 
> To keep the Git history lean and avoid limits, download the required toolchains yourself and drop them in **`prebuilts/`**.

## Warning about upcoming One UI 8.0

Please do not update to One UI 8.0 when it's released by Samsung.

Samsung has removed the option to unlock the bootloader in this version.

More details: [XDA Forum Thread](https://xdaforums.com/t/bootloader-unlocking-option-removed-from-one-ui-8-0.4751904/)

If you're into rooting, custom ROMs, or device modding, it's highly recommended to stay on One UI 7 for now.

## Introduction

This repository contains everything needed to build a custom kernel for the **Samsung Galaxy A56 (SM‑A566B)**.
It is based on kernel source **A566BXXS5AYFB**

My device is running just fine with **A566BXXS5AYFA** firmware.

## Patch Kernel

```bash
chmod +x setup_next.sh
./setup_next.sh # Install KernelSU-Next
chmod +x setup_susfs.sh
./setup_susfs.sh # Install SUSFS ඞ
chmod +x setup_scope_min_manual_hook.sh
./setup_scope_min_manual_hook.sh # Install Scope-Minimized Manual Hooks 
```

## Build Kernel

```bash
chmod +x build_script.sh
./build_script.sh
chmod +x create_boot-img.sh
./create_boot-img.sh # Create boot.img & boot.img.tar (Need stock boot.img in magiskboot)
```

## Download from Samsung/Google

Download sources and toolchains from:

* [https://opensource.samsung.com/uploadSearch?searchValue=A56](https://opensource.samsung.com/uploadSearch?searchValue=A56)
* [https://source.android.com/docs/setup/build/building-kernels](https://source.android.com/docs/setup/build/building-kernels)

```
repo init -u https://android.googlesource.com/kernel/manifest -b common-android15-6.6
repo sync
```
you may need to adjust the paths in ```build_script.sh```

## Disclaimer

The author(s) accept no liability for damages, data loss or warranty voids.

Flashing custom images trigger Knox permanently.

## Prebuilt Releases

If you just want a working kernel including KernelSU Next and susfs, download the **latest release**:

* [Latest releases](https://github.com/Luciiuss/sm-a566b/releases)

> 🚨 There is confirmation that the kernel is compatible with the SM-A566E, but compatibility is not guaranteed.
---

## Credits

Special thanks to the following projects and contributors:

* [**Samsung**](https://opensource.samsung.com/) — for providing the kernel source and boot image
* [**Magisk**](https://github.com/topjohnwu/Magisk) — for the `magiskboot` utility (by topjohnwu & contributors)
* [**KernelSU-Next**](https://github.com/KernelSU-Next/KernelSU-Next) — by [rifsxd](https://github.com/rifsxd)
* [**susfs4ksu**](https://gitlab.com/simonpunk/susfs4ksu) — by [simonpunk](https://gitlab.com/simonpunk)
* [**kernel_patches**](https://github.com/WildKernels/kernel_patches) — by [WildKernels](https://github.com/WildKernels/)
* Scope-Minimized Manual Hooks — by [backslashxx](https://github.com/backslashxx)
* Bluetooth fix — by [ReeViiS69](https://github.com/ReeViiS69)

---

### Enjoy! 🚀
