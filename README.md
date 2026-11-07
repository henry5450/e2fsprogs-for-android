# e2fsprogs for Android

将 [e2fsprogs](https://github.com/tytso/e2fsprogs) 1.47.4 交叉编译为 **Android 原生
(bionic / NDK)** 可执行文件，可在非 Termux 环境中直接运行。

- **目标平台**：`arm64-v8a`（默认），另支持 `arm`、`x86_64`、`x86`
- **最低 API**：26（Android 8.0）
- **工具链**：Android NDK（已在 r29 / clang 21 上测试）
- **运行依赖**：仅 Android 自带的 `libc.so`、`libdl.so`
  （libext2fs / libuuid / libblkid / libe2p / libss / libcom_err 全部静态链接）
- **不是 Termux 版本**：不需要 Termux、proot 或 glibc

## 构建

```sh
./android/build.sh                 # arm64-v8a，API 26
./android/build.sh x86_64          # 模拟器
API=30 ./android/build.sh          # 指定最低 API
NDK=/opt/android-ndk ./android/build.sh
```

产物位于 `tmp/`：

| 产物 | 说明 |
| --- | --- |
| `e2fsprogs-1.47.4-android-arm64.tar.gz` | 便携包，解包后 `bin/` 直接运行 |
| `e2fsprogs-ksu-module-arm64.zip` | KernelSU / Magisk 模块，安装到 `/system/bin` |

## 两种使用方式

### 1. 便携使用（无需 root）

```sh
adb push e2fsprogs-1.47.4-android-arm64 /data/local/tmp/e2fsprogs
adb shell
cd /data/local/tmp/e2fsprogs && export PATH=$PWD/bin:$PATH
e2fsck -V
mke2fs -t ext4 test.img 64M
```

### 2. 系统级安装（KernelSU / Magisk）

刷入 `e2fsprogs-ksu-module-<abi>.zip` 后重启。命令安装在 `/system/bin`
（Android 的 PATH 已包含该目录），配置自动读取 `/system/etc/mke2fs.conf`。

## 包含的命令

`e2fsck`、`mke2fs`（含 `mkfs.ext2/3/4`）、`tune2fs`、`dumpe2fs`、`debugfs`、
`resize2fs`、`badblocks`、`blkid`、`chattr`、`lsattr`、`e2image`、`e2undo`、
`e2freefrag`、`e2fuzz`、`e4crypt`、`e4defrag`、`filefrag`、`fsck`、`logsave`、
`mklost+found`、`uuidgen`、`e2label`、`e2mmpstatus`、`findfs`

## 已验证

- NDK r29 (clang 21)，API 26，arm64
- Android 16 设备上实际运行：`mke2fs` 建镜像、`debugfs` 读写、
  `e2fsck -fn`、`resize2fs` 扩容、`e2image` 备份均通过

## 关于本仓库

本仓库是上游 e2fsprogs **1.47.4 的源码快照**，额外添加了 `android/` 下的
交叉编译与打包脚本。为保持仓库贡献者列表单一，**未导入上游 git 历史**；
上游完整历史、更新与提交记录请见 <https://github.com/tytso/e2fsprogs>。

## 许可

e2fsprogs 以 **GPL-2.0** 发布；其中 `lib/ext2fs` 与 `lib/e2p` 为 LGPL-2.0，
`lib/uuid` 为 BSD 风格许可，`lib/et`、`lib/ss` 为 MIT 风格许可。
完整声明见仓库根目录的 [`NOTICE`](NOTICE) 及各源文件头部。
