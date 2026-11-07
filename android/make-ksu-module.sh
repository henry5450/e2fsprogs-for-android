#!/bin/sh
# Build a KernelSU/Magisk module that installs e2fsprogs into /system/bin.
#   ./android/make-ksu-module.sh [ABI] [PACKAGE_DIR]
set -eu

TOP=$(cd "$(dirname "$0")/.." && pwd)
ABI=${1:-arm64}
VER=$(sed -n 's/^#define E2FSPROGS_VERSION "\(.*\)"/\1/p' "$TOP/version.h")
[ -n "$VER" ] || { echo "cannot determine version from version.h" >&2; exit 1; }
PKG=${2:-$TOP/tmp/e2fsprogs-$VER-android-$ABI}
MOD=$TOP/tmp/e2fsprogs-ksu-module-$ABI
ZIP=$TOP/tmp/e2fsprogs-ksu-module-$ABI.zip
VERSION_CODE=$(echo "$VER" | awk -F. '{printf "%d%02d%02d", $1, $2, $3}')

rm -rf "$MOD"
mkdir -p "$MOD/system/bin"

# Real copies instead of symlinks: KernelSU's zip extractor is not guaranteed
# to restore symlinks, and these tools dispatch on argv[0].
for p in e2fsck debugfs badblocks blkid chattr dumpe2fs e2freefrag e2fuzz \
	e2image e2initrd_helper e2undo e4crypt e4defrag filefrag fsck logsave \
	lsattr mke2fs mklost+found resize2fs tune2fs uuidgen; do
	cp "$PKG/bin/$p" "$MOD/system/bin/$p"
done
cp "$PKG/bin/e2fsck"    "$MOD/system/bin/fsck.ext2"
cp "$PKG/bin/e2fsck"    "$MOD/system/bin/fsck.ext3"
cp "$PKG/bin/e2fsck"    "$MOD/system/bin/fsck.ext4"
cp "$PKG/bin/tune2fs"   "$MOD/system/bin/e2label"
cp "$PKG/bin/tune2fs"   "$MOD/system/bin/findfs"
cp "$PKG/bin/dumpe2fs"  "$MOD/system/bin/e2mmpstatus"
# mkfs.ext2/3/4 are intentionally NOT installed: the ROM already ships
# /system/bin/mkfs.ext* wrappers that exec /system/bin/mke2fs.

chmod 755 "$MOD"/system/bin/*

cat > "$MOD/module.prop" <<EOF
id=e2fsprogs
name=e2fsprogs $VER
version=v$VER
versionCode=$VERSION_CODE
author=e2fsprogs-for-android
description=Native Android (bionic/NDK) e2fsprogs tools in /system/bin. Config is read from /system/etc/mke2fs.conf. Includes e2fsck, mke2fs, debugfs, tune2fs, dumpe2fs, resize2fs, badblocks, blkid, e2image, e2undo, e4defrag and friends.
EOF

cat > "$MOD/README.md" <<EOF
# e2fsprogs (Android bionic build) KernelSU/Magisk module

Installs e2fsprogs $VER into \`/system/bin\`. Internal libraries are statically
linked; the binaries only depend on Android's \`libc.so\` / \`libdl.so\`.
No Termux or glibc is involved.

- Reads its configuration from \`/system/etc/mke2fs.conf\` (shipped by Android).
- Does not override \`/system/bin/mkfs.ext2/3/4\` (the ROM wrappers exec \`mke2fs\`).
- Overrides the toybox links \`chattr\`, \`lsattr\`, \`uuidgen\` and the ROM's \`e2freefrag\`.

Flash this zip with KernelSU or Magisk, then reboot.
EOF

cd "$TOP/tmp"
rm -f "$ZIP"
(cd "$MOD" && zip -qr "$ZIP" .)
sha256sum "$ZIP" > "$ZIP.sha256"
echo "module: $ZIP"
