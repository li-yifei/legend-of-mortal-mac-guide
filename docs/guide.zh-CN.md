# 在 Apple Silicon Mac 上运行《活侠传》：安装、字体与 Mod 修复

[返回首页](../README.md) · [日本語](guide.ja.md) · [한국어](guide.ko.md)

本文记录一套在 2026 年 8 月实际跑通的配置。它适用于希望通过 Sikarugir、Wine 和 Windows Steam 运行自己购买的《活侠传》的 Apple Silicon Mac 用户。

## 已验证环境

| 项目 | 版本或结果 |
| --- | --- |
| 游戏 | Steam AppID `1859910`，Build ID `20337760`，`release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 游戏进程 | `Mortal.exe`，PE32 / x86 |
| 包装器 | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| 图形后端 | 32 位 DXMT，D3D11 → Metal |
| Mod 框架 | BepInEx `6.0.0-be.785` x86 Mono |

Wine、Steam、macOS 和游戏更新都可能改变结果。保留版本号、日志和时间戳备份。

## 1. 建立独立的 Windows Steam 包装器

准备以下内容：

- Apple Silicon Mac 与 macOS 14 或更高版本；
- Rosetta 2；
- [Sikarugir 官方项目](https://github.com/Sikarugir-App/Sikarugir)；
- 自己拥有的 [Steam《活侠传》](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)；
- 足够存放包装器、Steam、游戏和备份的磁盘空间。

使用 Sikarugir Creator 创建独立包装器，例如 `SteamWin.app`。在包装器自己的 prefix 中依次完成：

1. 初始化 Wine prefix，确认同时存在 `Program Files` 与 `Program Files (x86)`；
2. 通过 Winetricks 安装 `cjkfonts`；
3. 应用 `hidewineexports=enable`；
4. 安装 Windows 版 Steam；
5. 将启动目标设为 `C:\Program Files (x86)\Steam\steam.exe`；
6. 登录 Steam 并安装 AppID `1859910`。

原生 macOS Steam 与 Windows Steam 可以共存。登录或连接异常时，先完整退出另一套客户端，避免同一账号会话互相替换。

### 先确认游戏架构

Steam 商店的操作系统要求无法代替文件检查。运行：

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

已验证 build 的结果：

```text
PE32 executable (GUI) Intel 80386, for MS Windows
```

Windows Steam 的 x86 bootstrap 很常见。图形后端应根据 `Mortal.exe` 的 PE32 架构选择。

## 2. 修复 D3D11 图形初始化失败

典型症状：Steam 短暂显示“运行中”，随后游戏退出；弹窗或 `Player.log` 出现：

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

已验证 build 的路线结果：

- Unity OpenGL：游戏构建缺少对应 graphics device；
- WineD3D + MoltenVK：识别 Apple GPU，D3D feature level 协商失败；
- D3DMetal：主要覆盖 64 位 D3D11/12；
- DXMT：提供 32 位 D3D10/11 模块，适合当前 PE32 游戏。

### DXMT 开关生效的判断标准

包装器界面显示 DXMT 只代表配置已写入。运行时还要检查：

- `WINEDEBUG=+loaddll` 是否加载目标 `d3d11.dll`、`dxgi.dll` 与 `winemetal.dll`；
- 活动 Engine DLL 的 SHA-256 是否与目标 DXMT 版本一致；
- `Player.log` 是否报告 D3D11 level 11.1 与 Apple GPU。

这套环境的 DXMT 开关最初仍让游戏加载 Engine 目录中的 WineD3D。最终采用可回滚的 Engine 级修复：备份原始 32 位 WineD3D 模块，把匹配版本的 DXMT `d3d10core.dll`、`d3d11.dll`、`dxgi.dll`、`winemetal.dll` 放入实际活动的 `i386-windows` 目录，并把匹配的 `winemetal.so` 放入活动 Unix module 目录。

Engine 的目录结构会变化。先从加载日志解析真实路径，再进行替换。每个文件都应记录替换前后的 SHA-256。

成功日志：

```text
Loaded C:\windows\system32\winemetal.dll
Loaded C:\windows\system32\DXGI.DLL
Loaded C:\windows\system32\d3d11.dll
```

Unity 成功证据：

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
Begin MonoManager ReloadAssembly
```

日常启动使用 Steam AppID：

```text
steam.exe -applaunch 1859910
```

## 3. Retina 与分辨率

Wine Retina 模式对应：

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina 渲染与 Unity UI 缩放相互独立。《活侠传》的 Unity UI 基本忽略 Windows DPI。高分辨率提供更清晰的画面与更小的 UI，低分辨率提供更大的 UI 与更明显的放大模糊。

推荐让游戏记住用户选择的窗口分辨率。已验证环境最终采用 `1920×1200`，桌面启动器取消强制 `-screen-width` 与 `-screen-height`。

## 4. 修复商店价格和总额消失

典型症状是中文、普通数字和钱币图标都能显示，商店价格与总额为空。

资源检查显示，`MoneyValue` 和 `MoneyText` 绑定内嵌的 `SourceHanSerifTC-Bold`；默认文本包含 `50`，字体图集也包含 `0–9`。问题集中在 Wine prefix 的字体集合与映射。

早期 prefix 只有：

```text
sourcehansans.ttc
unifont.ttf
```

`cjkfonts` 已经安装，覆盖范围仍然有限。实际修复采用 Winetricks：

```text
fonts → allfonts
```

操作前完整退出 Windows Steam，并备份：

- `drive_c/windows/Fonts`；
- `system.reg`；
- `user.reg`；
- `userdef.reg`。

安装后，字体目录从 2 个文件增加到 121 个，约 284 MB，Arial、Tahoma、Calibri、Meiryo 和 WenQuanYi 等注册项完整写入。结束 wineserver 并重启游戏后，金额显示恢复。

字体具有各自的授权条款。通过 Winetricks 原始来源安装，公开仓库与预装包装器保持零字体分发。

## 5. 修复 Doorstop/BepInEx Mod 加载

### 安装 Mod 时先做文件级备份

对每个压缩包执行：

1. 检查绝对路径与 `..` 路径穿越；
2. 检查 `winhttp.dll` 与插件 DLL 的 x86 架构；
3. 列出将被覆盖的文件；
4. 复制同名文件到时间戳备份目录；
5. 合并后逐项校验 SHA-256；
6. 启动并确认日志修改时间属于本次运行。

安装包可能携带旧 `LogOutput.log`。框架状态应结合日志修改时间、当前进程模块和 Chainloader 输出判断。

### 第一步：加载 Doorstop

在 `winecfg → Libraries` 为游戏增加：

```text
winhttp = native,builtin
```

优先使用仅作用于 `Mortal.exe` 的应用级 DLL override。运行时应能观察到本地 `winhttp.dll` 与 BepInEx Preloader。

### 第二步：提供匹配 Unity 版本的完整 corlibs

已验证游戏自带的 `Mortal_Data/Managed/mscorlib.dll` 为 `3,906,048` 字节；匹配 Unity `2020.3.49f1` 的完整版本为 `4,065,792` 字节。

将合法取得、版本匹配的完整 corlibs 放入：

```text
BepInEx/unstripped_corlib/
```

配置 `doorstop_config.ini`：

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibs 必须与 Unity 版本匹配，并遵守 Unity 的许可条款。仓库和 Mod 包保持零 corlibs 分发。

### 第三步：使用包含 Wine 修复的 BepInEx 6

旧 BepInEx 6 在 Wine 32 位环境可能抛出：

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

该问题由 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201) 记录，并由 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) 修复。已验证组合使用包含该修复的 x86 Mono 构建 `6.0.0-be.785`。替换前完整备份 `BepInEx/core`。

成功日志包含：

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

随后应逐个出现插件加载记录。已验证环境中 DiceMaster 与日文 Mod 的 5 个插件均成功进入 Chainloader。

## 6. 日常维护

- 关闭 Steam 全局 Overlay 与《活侠传》的单游戏 Overlay，降低切换 App 后的输入锁死概率。
- 游玩期间使用 `caffeinate`。盒盖休眠、锁屏或显示器热插拔后，完整刷新游戏、Windows Steam 与 wineserver 会话。
- Windows Steam 长时间运行后可能停止接收 `-applaunch`。Steam `gameprocess_log.txt` 没有新记录时，刷新该 prefix 的 Steam/Wine 会话。
- 使用 Windows Steam 菜单的 `Steam → Exit` 退出。Dock 中的 Wine 图标代表 macOS 窗口代理。

## 7. 使用随仓库提供的只读检查器

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

脚本只读取包装器、游戏架构、Steam manifest、注册表、字体数量、DXMT 模块哈希、BepInEx 日志和当前进程。它不会启动或结束 Wine、Steam、游戏会话，也不会修改文件。

## 参考资料

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [BepInEx Wine 修复](https://github.com/BepInEx/BepInEx/pull/1254)
- [《活侠传》日文 Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
