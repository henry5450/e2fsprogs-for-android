#!/bin/bash
# Cross-compile e2fsprogs for Android (bionic, non-Termux) with the NDK.
#
#   ./android/build.sh [ABI]        ABI: arm64 (default) | arm | x86_64 | x86
#   API=26 ./android/build.sh       # minimum Android API level
#   NDK=/path/to/ndk ./android/build.sh
#
# Output (under tmp/):
#   e2fsprogs-<version>-android-<abi>/        portable tree
#   e2fsprogs-<version>-android-<abi>.tar.gz  portable package
#   e2fsprogs-ksu-module-<abi>.zip            KernelSU/Magisk module
set -euo pipefail

TOP=$(cd "$(dirname "$0")/.." && pwd)
ABI=${1:-arm64}
API=${API:-26}
NDK=${NDK:-${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-/Application/android-ndk-r29}}}
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64

case $ABI in
	arm64)  TRIPLE=aarch64-linux-android ;;
	arm)    TRIPLE=armv7a-linux-androideabi ;;
	x86_64) TRIPLE=x86_64-linux-android ;;
	x86)    TRIPLE=i686-linux-android ;;
	*) echo "unknown ABI: $ABI" >&2; exit 1 ;;
esac

[ -x "$TOOLCHAIN/bin/${TRIPLE}${API}-clang" ] || {
	echo "NDK toolchain not found: $TOOLCHAIN" >&2
	echo "Set NDK=/path/to/android-ndk (API $API for $ABI is required)" >&2
	exit 1
}

BUILD=$TOP/tmp/build-android-$ABI
mkdir -p "$BUILD"
cd "$BUILD"

CC=$TOOLCHAIN/bin/${TRIPLE}${API}-clang \
AR=$TOOLCHAIN/bin/llvm-ar \
RANLIB=$TOOLCHAIN/bin/llvm-ranlib \
STRIP=$TOOLCHAIN/bin/llvm-strip \
CFLAGS="-O2 -pipe -fno-strict-aliasing" \
	"$TOP/configure" \
	--host="$TRIPLE" --build="$(gcc -dumpmachine)" \
	--prefix=/system/usr --exec-prefix=/system \
	--bindir=/system/bin --sbindir=/system/bin --sysconfdir=/system/etc \
	--disable-nls --disable-elf-shlibs --disable-bsd-shlibs --disable-uuidd \
	--disable-fuse2fs --disable-fuse4fs --disable-tdb --disable-backtrace \
	--without-libarchive --without-libintl-prefix --without-libiconv-prefix

make -j"$(nproc)"

"$TOP/android/make-package.sh" "$ABI" "$BUILD"
"$TOP/android/make-ksu-module.sh" "$ABI"
