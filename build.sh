#!/bin/bash

# Import KernelSU-Next
(cd ./kernel_platform/common/ && curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s dev)

# Import toolchain
KERNEL_PLATFORM="${ANDROID_BUILD_TOP}/kernel_platform"
TOOLCHAIN_URL="https://github.com/GoRhanHee/android_kernel_samsung_sm8750_pa2q/releases/download/toolchain"
if [ ! -d "${KERNEL_PLATFORM}/prebuilts" ]; then

    TOOLCHAIN_TMP=$(mktemp -d)

    curl -fL --retry 3 \
        "${TOOLCHAIN_URL}/toolchain.z01" \
        -o "${TOOLCHAIN_TMP}/toolchain.z01"

    curl -fL --retry 3 \
        "${TOOLCHAIN_URL}/toolchain.zip" \
        -o "${TOOLCHAIN_TMP}/toolchain.zip"

    (
        cd "${TOOLCHAIN_TMP}" || exit 1

        zip -s 0 toolchain.zip --out toolchain-full.zip

        unzip -q toolchain-full.zip

        mkdir -p extracted
        tar -xzf toolchain.tar.gz -C extracted

        cp -a extracted/kernel_platform/prebuilts "${KERNEL_PLATFORM}/"
    )

    rm -rf "${TOOLCHAIN_TMP}"
fi

#1. target config
BUILD_TARGET=pa2q_kor_singlex
export MODEL=$(echo $BUILD_TARGET | cut -d'_' -f1)
export PROJECT_NAME=${MODEL}
export REGION=$(echo $BUILD_TARGET | cut -d'_' -f2)
export CARRIER=$(echo $BUILD_TARGET | cut -d'_' -f3)
export TARGET_BUILD_VARIANT=user
		
		
#2. sm8750 common config
CHIPSET_NAME=sun

export ANDROID_BUILD_TOP=$(pwd)
export TARGET_PRODUCT=perf
export TARGET_BOARD_PLATFORM=gki

export ANDROID_PRODUCT_OUT=${ANDROID_BUILD_TOP}/out/target/product/${MODEL}
export OUT_DIR=${ANDROID_BUILD_TOP}/out/msm-${CHIPSET_NAME}-${CHIPSET_NAME}-${TARGET_PRODUCT}

# for Lcd(techpack) driver build
export KBUILD_EXTRA_SYMBOLS=${ANDROID_BUILD_TOP}/out/vendor/qcom/opensource/mmrm-driver/Module.symvers

# for Audio(techpack) driver build
export MODNAME=audio_dlkm

export KBUILD_EXT_MODULES="\
	../vendor/qcom/opensource/mmrm-driver \
        ../vendor/qcom/opensource/mm-drivers/msm_ext_display \
        ../vendor/qcom/opensource/mm-drivers/sync_fence \
        ../vendor/qcom/opensource/mm-drivers/hw_fence \
        ../vendor/qcom/opensource/securemsm-kernel \
        "

#3. build kernel
cd ./kernel_platform/

# Only cook common GKI Kernel
./tools/bazel run //common:kernel_aarch64_dist -- \
    --dist_dir="${ANDROID_BUILD_TOP}/out/common-kernel/dist"
