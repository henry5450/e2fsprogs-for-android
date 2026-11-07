# Android build

用 Android NDK (bionic) 交叉编译 e2fsprogs，生成可在非 Termux 环境直接运行的
arm64 / x86_64 / arm / x86 原生二进制。

## 依赖

- Linux 主机，`make`、`gcc`、`bison`、`flex`
- Android NDK r26+（已在 r29 上测试）
- NDK 路径可通过 `NDK`、`ANDROID_NDK_HOME` 或 `ANDROID_NDK_ROOT` 指定

## 构建

```sh
./android/build.sh                 # arm64-v8a，最低 API 26
./android/build.sh x86_64          # 模拟器
API=30 ./android/build.sh          # 指定最低 API
NDK=/opt/android-ndk ./android/build.sh
```

产物位于 `tmp/`：

```
tmp/e2fsprogs-<ver>-android-<abi>/          便携目录（bin/ etc/ share/）
tmp/e2fsprogs-<ver>-android-<abi>.tar.gz    便携包
tmp/e2fsprogs-ksu-module-<abi>.zip          KernelSU / Magisk 模块
```

## 关键配置

- `--prefix=/system/usr --exec-prefix=/system`
- `--bindir=/system/bin --sbindir=/system/bin --sysconfdir=/system/etc`
  因此编译期默认读取 `/system/etc/mke2fs.conf`，无需 `MKE2FS_CONFIG`
- 仅构建静态内部库（`--disable-elf-shlibs`），最终二进制只依赖
  `libc.so` 与 `libdl.so`
- 关闭 NLS、uuidd、fuse2fs/fuse4fs、tdb、backtrace、libarchive

## bionic 兼容性

- 最低 API 定为 26：bionic 从 API 26 才提供 `hasmntopt()`
- 其余代码在 bionic 上无需修改即可编译（上游 1.47.x 已包含 musl/非 glibc 的修复）
