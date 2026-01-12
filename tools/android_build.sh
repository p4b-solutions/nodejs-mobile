#!/bin/bash

set -e

ROOT=${PWD}

if [ $# -lt 2 ]; then
  echo "Requires a path to the Android NDK and an SDK version number (optionally: target arch)"
  echo "Usage: android_build.sh <ndk_path> <sdk_version> [target_arch]"
  exit 1
fi

ANDROID_SDK_VERSION="$2"

SCRIPT_DIR="$(dirname "$BASH_SOURCE")"
cd "$SCRIPT_DIR"
SCRIPT_DIR=${PWD}

cd "$ROOT"
cd "$1"
ANDROID_NDK_PATH=${PWD}
cd "$SCRIPT_DIR"
cd ../

BUILD_ARCH() {
  # Clean previous compilation
  make clean
  rm -rf android-toolchain/

  # Compile
  eval '"./android-configure" "$ANDROID_NDK_PATH" $ANDROID_SDK_VERSION $TARGET_ARCH'

  # Patch Makefile to disable Thin Archives (not supported by macOS host implementation of ar/ld)
  # Using perl for portability across macOS/Linux
  perl -pi -e 's/crsT/crs/g' out/Makefile

  HOST_OS=$(uname -s)
  if [ "$HOST_OS" == "Darwin" ]; then
      TOOLCHAIN_HOST="darwin-x86_64"
  elif [ "$HOST_OS" == "Linux" ]; then
      TOOLCHAIN_HOST="linux-x86_64"
  fi
  NDK_AR="${ANDROID_NDK_PATH}/toolchains/llvm/prebuilt/${TOOLCHAIN_HOST}/bin/llvm-ar"
  
  make AR="${NDK_AR}" -j $(getconf _NPROCESSORS_ONLN)

  # Move binaries
  TARGET_ARCH_FOLDER="$TARGET_ARCH"
  if [ "$TARGET_ARCH_FOLDER" == "arm" ]; then
    # Use the Android NDK ABI name.
    TARGET_ARCH_FOLDER="armeabi-v7a"
  elif [ "$TARGET_ARCH_FOLDER" == "arm64" ]; then
    # Use the Android NDK ABI name.
    TARGET_ARCH_FOLDER="arm64-v8a"
  fi
  mkdir -p "out_android/$TARGET_ARCH_FOLDER/"
  OUTPUT1="out/Release/lib.target/libnode.so"
  OUTPUT2="out/Release/obj.target/libnode.so"
  if [ -f "$OUTPUT1" ]; then
    cp "$OUTPUT1" "out_android/$TARGET_ARCH_FOLDER/libnode.so"
  elif [ -f "$OUTPUT2" ]; then
    cp "$OUTPUT2" "out_android/$TARGET_ARCH_FOLDER/libnode.so"
  else
    echo "Could not find libnode.so file after compilation"
    exit 1
  fi
}

if [ $# -eq 2 ]; then
  TARGET_ARCH="arm"
  BUILD_ARCH
  # TARGET_ARCH="x86"
  # BUILD_ARCH
  TARGET_ARCH="arm64"
  BUILD_ARCH
  TARGET_ARCH="x86_64"
  BUILD_ARCH
else
  TARGET_ARCH=$3
  BUILD_ARCH
fi

source $SCRIPT_DIR/copy_libnode_headers.sh android

cd "$ROOT"
