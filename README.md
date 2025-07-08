# Samsung Galaxy A56 (SM‑A566B)

> ⚠️ **Toolchains are *not* included in this repository.** ⚠️
> 
> To keep the Git history lean and avoid limits, download the required toolchains yourself and drop them in **`prebuilts/`**.

## Introduction

This repository contains everything needed to build a custom kernel for the **Samsung Galaxy A56 (SM‑A566B)**.
It is based on firmware **A566BXXS4AYE5**
If you need a newer firmware version, please download the source code from Samsung.

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

> 🚨 Make sure your device matches the base firmware to avoid bootloop.

---

## Credits

Special thanks to the following projects and contributors:

* [**Magisk**](https://github.com/topjohnwu/Magisk) — for the `magiskboot` utility (by topjohnwu & contributors)
* [**KernelSU-Next**](https://github.com/KernelSU-Next/KernelSU-Next) — by [rifsxd](https://github.com/rifsxd)
* [**susfs4ksu**](https://gitlab.com/simonpunk/susfs4ksu) — by [simonpunk](https://gitlab.com/simonpunk)
* [**kernel_patches**](https://github.com/WildKernels/kernel_patches) — by [WildKernels](https://github.com/WildKernels/)
* Scope-Minimized Manual Hooks — by [backslashxx](https://github.com/backslashxx)
* Bluetooth fix — by [ReeViiS69](https://github.com/ReeViiS69)

---

### Enjoy! 🚀
