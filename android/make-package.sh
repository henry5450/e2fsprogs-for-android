#!/bin/sh
# Build a distributable Android package from a cross-build tree.
#   ./android/make-package.sh [ABI] [BUILD_DIR]
set -eu

TOP=$(cd "$(dirname "$0")/.." && pwd)
ABI=${1:-arm64}
BUILD_DIR=${2:-$TOP/tmp/build-android-$ABI}
BUILD_DIR=$(cd "$BUILD_DIR" && pwd)
VER=$(sed -n 's/^#define E2FSPROGS_VERSION "\(.*\)"/\1/p' "$TOP/version.h")
[ -n "$VER" ] || { echo "cannot determine version from version.h" >&2; exit 1; }
NAME=e2fsprogs-$VER-android-$ABI
OUT=$TOP/tmp/$NAME

NDK=${NDK:-${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-/Application/android-ndk-r29}}}
TC=${TOOLCHAIN:-$NDK/toolchains/llvm/prebuilt/linux-x86_64}

rm -rf "$OUT"
mkdir -p "$OUT/bin" "$OUT/etc" "$OUT/share/man/man1" \
	"$OUT/share/man/man5" "$OUT/share/man/man8"

PROGS="e2fsck debugfs badblocks blkid chattr dumpe2fs e2freefrag e2fuzz
e2image e2initrd_helper e2undo e4crypt e4defrag filefrag fsck logsave lsattr
mke2fs mklost+found resize2fs tune2fs uuidgen"

for p in $PROGS; do
	case $p in
		e2fsck) src=$BUILD_DIR/e2fsck/e2fsck ;;
		debugfs) src=$BUILD_DIR/debugfs/debugfs ;;
		resize2fs) src=$BUILD_DIR/resize/resize2fs ;;
		*) src=$BUILD_DIR/misc/$p ;;
	esac
	"$TC/bin/llvm-strip" --strip-all -o "$OUT/bin/$p" "$src"
done

# Same convenience links as 'make install'
cd "$OUT/bin"
ln -s mke2fs mkfs.ext2
ln -s mke2fs mkfs.ext3
ln -s mke2fs mkfs.ext4
ln -s e2fsck fsck.ext2
ln -s e2fsck fsck.ext3
ln -s e2fsck fsck.ext4
ln -s dumpe2fs e2mmpstatus
ln -s tune2fs e2label
ln -s tune2fs findfs

cp "$BUILD_DIR/misc/mke2fs.conf" "$OUT/etc/"

# man pages
for m in "$BUILD_DIR"/misc/*.8; do cp "$m" "$OUT/share/man/man8/"; done
cp "$BUILD_DIR"/e2fsck/e2fsck.8 "$OUT/share/man/man8/"
cp "$BUILD_DIR"/debugfs/debugfs.8 "$OUT/share/man/man8/"
cp "$BUILD_DIR"/resize/resize2fs.8 "$OUT/share/man/man8/"
cp "$BUILD_DIR"/misc/mke2fs.conf.5 "$OUT/share/man/man5/"
cp "$BUILD_DIR"/misc/ext4.5 "$OUT/share/man/man5/"
for m in "$BUILD_DIR"/misc/*.1; do [ -f "$m" ] && cp "$m" "$OUT/share/man/man1/"; done

{
	echo "e2fsprogs $VER for Android ($ABI)"
	echo "NDK: $NDK"
	echo "CC:  $(sed -n 's/^CC = //p' "$BUILD_DIR/MCONFIG")"
	echo "CFLAGS: $(sed -n 's/^CFLAGS = //p' "$BUILD_DIR/MCONFIG")"
	echo "configure:$(grep -m1 '^  \$ .*configure' "$BUILD_DIR/config.log" | sed 's/^  \$ //')"
} > "$OUT/build-info.txt"

cat > "$OUT/README.md" <<EOF
# e2fsprogs $VER — Android (bionic) native build

Cross-compiled with the Android NDK, target **$ABI**, minimum API 26.
Internal libraries (libext2fs/libuuid/libblkid/libe2p/libss/libcom_err) are
linked statically; the binaries only depend on Android's \`libc.so\` and \`libdl.so\`.

**This is not a Termux build**: no Termux, proot or glibc is involved.

The compiled-in config directory is **/system/etc** (Android's existing
\`/system/etc/mke2fs.conf\` is used automatically). To use the desktop-style
config shipped in this package instead, set
\`MKE2FS_CONFIG=\$PWD/etc/mke2fs.conf\`.

## Usage

\`\`\`sh
adb push $NAME /data/local/tmp/e2fsprogs

adb shell
cd /data/local/tmp/e2fsprogs
export PATH=\$PWD/bin:\$PATH

e2fsck -V
mke2fs -t ext4 test.img 64M
e2fsck -fn test.img
\`\`\`

## Install to /system/bin (KernelSU / Magisk)

Flash \`e2fsprogs-ksu-module-$ABI.zip\` with KernelSU or Magisk and reboot.
The commands are then available everywhere (\`/system/bin\` is already in PATH)
and read \`/system/etc/mke2fs.conf\` with no environment variables required.

## Root

Block devices (\`/dev/block/...\`), \`mount\`, \`e4defrag\` and \`chattr\` need root:

\`\`\`sh
su -c 'e2fsck -fy /dev/block/by-name/userdata'
\`\`\`

## Included commands

e2fsck, mke2fs (mkfs.ext2/3/4), tune2fs, dumpe2fs, debugfs, resize2fs,
badblocks, blkid, chattr, lsattr, e2image, e2undo, e2freefrag, e2fuzz,
e4crypt, e4defrag, filefrag, fsck, logsave, mklost+found, uuidgen,
e2label, e2mmpstatus, findfs

## Rebuild

\`\`\`sh
./android/build.sh              # arm64, API 26
./android/build.sh x86_64       # emulator
NDK=/path/to/ndk API=30 ./android/build.sh
\`\`\`
EOF

cd "$TOP/tmp"
tar czf "$NAME.tar.gz" "$NAME"
sha256sum "$NAME.tar.gz" > "$NAME.tar.gz.sha256"
echo "package: $TOP/tmp/$NAME.tar.gz"
