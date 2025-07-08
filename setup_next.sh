#!/bin/bash
set -e

cd "$(dirname "$0")/kernel-6.6"
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -
