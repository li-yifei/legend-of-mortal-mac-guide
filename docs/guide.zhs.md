# 在 Apple Silicon Mac 上运行《活侠传》：安装、字体与 Mod 修复

[返回首页](../README.md) · [繁體中文](guide.zht.md) · [日本語](guide.ja.md) · [한국어](guide.ko.md)

本文记录了一套在 2026 年 8 月经实机验证可行的配置方案，适用于希望通过 Sikarugir、Wine 与 Windows 版 Steam 运行自购正版《活侠传》的 Apple Silicon Mac 用户。

## 已验证环境

| 项目 | 已验证配置 |
| --- | --- |
| 游戏 | Steam AppID `1859910`，Build ID `20337760`，`release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 可执行文件 | `Mortal.exe`，PE32 / x86 |
| 包装器（Wrapper） | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| 图形后端 | 32 位 DXMT，D3D11 → Metal |
| Mod 框架 | BepInEx `6.0.0-be.785` x86 Mono |

Wine、Steam、macOS 与游戏本身的更新均可能影响兼容性与运行结果。在进行任何调整时，请务必记录版本号、保留日志并创建带时间戳的备份。

## 1. 建立独立的 Windows 版 Steam 包装器

请先准备以下环境与资源：

- Apple Silicon Mac 与 macOS 14 或更高版本；
- Rosetta 2；
- [Sikarugir 官方项目](https://github.com/Sikarugir-App/Sikarugir)；
- 个人 Steam 账户中已购买的 [《活侠传》](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)；
- 足够的磁盘空间（用于存放包装器、Steam、游戏本体与各阶段备份）。

使用 Sikarugir Creator 创建独立包装器（例如 `SteamWin.app`）。在包装器专属的 Wine prefix 中依次完成以下操作：

1. 初始化 Wine prefix，确认已同时生成 `Program Files` 与 `Program Files (x86)` 目录；
2. 通过 Winetricks 安装 `cjkfonts`；
3. 应用注册表设置 `hidewineexports=enable`；
4. 安装 Windows 版 Steam；
5. 将启动目标设为 `C:\Program Files (x86)\Steam\steam.exe`；
6. 登录 Steam 并下载安装 AppID `1859910`。

macOS 原生 Steam 与 Windows 版 Steam 可以共存。如遇登录或网络连接异常，请先彻底退出另一端的客户端，避免同一账号的会话发生冲突或被强制下线。

### 先确认游戏架构

Steam 商店页面的系统要求无法替代实际的文件架构检查。请运行以下命令：

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

实测构建版本（Build）的检查结果：

```text
PE32 executable (GUI) Intel 80386, for MS Windows
```

Windows 版 Steam 虽然本身常见 32 位引导程序，但图形后端的选择必须以游戏主程序 `Mortal.exe` 本身的 PE32（32 位）架构为准。

## 2. 修复 D3D11 图形初始化失败

典型症状：Steam 短暂显示“运行中”后游戏异常退出；弹出错误窗口或在 `Player.log` 中记录：

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

在已验证环境中测试各类图形渲染后端的结果如下：

- Unity OpenGL：游戏本身缺少对应的图形设备（Graphics Device）支持；
- WineD3D + MoltenVK：虽能识别 Apple GPU，但在 Direct3D 功能级别（Feature Level）协商阶段失败；
- D3DMetal：主要覆盖 64 位的 D3D11/D3D12，无法直接用于 32 位游戏；
- DXMT：提供完整的 32 位 D3D10/11 模块，适配当前 32 位（PE32）游戏。

### 判断 DXMT 开关是否真正生效

在包装器界面中开启 DXMT 仅代表配置已写入。运行时还需进一步核验：

- `WINEDEBUG=+loaddll` 日志中是否确实加载了目标 `d3d11.dll`、`dxgi.dll` 与 `winemetal.dll`；
- 当前生效的 Engine DLL 的 SHA-256 哈希值是否与目标 DXMT 版本一致；
- `Player.log` 是否报告了 Direct3D 11 level 11.1 与 Apple GPU。

在实测环境中，初次在界面开启 DXMT 时，游戏实际仍加载了 Engine 目录中的 WineD3D。最终采用可安全回滚的 Engine 层修复方案：先备份原始 32 位 WineD3D 模块，再将对应版本的 DXMT 模块（`d3d10core.dll`、`d3d11.dll`、`dxgi.dll`、`winemetal.dll`）放入实际生效的 `i386-windows` 目录，并将匹配的 `winemetal.so` 放入对应的 Unix 模块目录。

不同 Engine 的目录结构可能存在差异。请先从加载日志中解析出真实的搜索路径后再进行替换，且每个文件在替换前后均应记录 SHA-256 哈希值。

成功加载日志示例：

```text
Loaded C:\windows\system32\winemetal.dll
Loaded C:\windows\system32\DXGI.DLL
Loaded C:\windows\system32\d3d11.dll
```

Unity 初始化成功日志示例：

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple <GPU>
Begin MonoManager ReloadAssembly
```

日常启动建议使用 Steam AppID 命令行参数：

```text
steam.exe -applaunch 1859910
```

## 3. Retina 与分辨率设置

Wine Retina 模式对应的注册表路径：

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina 渲染与 Unity UI 缩放是相互独立的机制。《活侠传》的 Unity UI 逻辑基本忽略 Windows DPI 设置。高分辨率能提供更清晰细腻的画面，但 UI 相对偏小；较低分辨率下 UI 尺寸较大，但会有明显的拉伸模糊。

建议让游戏记住用户自行选择的窗口分辨率。已验证环境最终采用 `1920×1200`，并在桌面快捷方式的启动参数中移除了强制的 `-screen-width` 与 `-screen-height` 参数。

## 4. 修复商店价格与总额显示空白

典型症状：游戏内的中文对话、常规数值与铜钱图标均能正常显示，但商店界面中的商品单价与总计金额显示为空白。

经 Unity 资源检查确认，`MoneyValue` 与 `MoneyText` UI 组件绑定了内嵌字体 `SourceHanSerifTC-Bold`；其默认文本包含 `50`，字体图集中也完整包含 `0–9` 数字字符。问题根源在于 Wine prefix 中的字体集合与系统字体映射不完整。

初始创建的 prefix 仅包含：

```text
sourcehansans.ttc
unifont.ttf
```

即使已安装 `cjkfonts`，其覆盖范围依然有限。实际修复方案为通过 Winetricks 安装：

```text
fonts → allfonts
```

操作前请彻底退出 Windows 版 Steam，并备份以下文件：

- `drive_c/windows/Fonts`；
- `system.reg`；
- `user.reg`；
- `userdef.reg`。

安装完成后，字体目录从 2 个文件增加到 121 个（约 284 MB），Arial、Tahoma、Calibri、Meiryo 与 WenQuanYi 等字体的注册表项均已完整写入。结束 wineserver 进程并重启游戏后，商店金额即可恢复正常显示。

各类字体均有其独立的软件许可协议。请一律通过 Winetricks 从原始来源下载安装，公开仓库与预打包包装器应保持零字体分发。

## 5. 修复 Doorstop 与 BepInEx Mod 加载

详细排障过程请参见案例分析：[案例：Wine 10 / x86 版《活侠传》加载日文 Mod](cases/japanese-mod.zhs.md)。

### 安装 Mod 前先做文件级备份

对每个压缩包执行以下操作：

1. 检查压缩包内路径，排除绝对路径与 `..` 路径穿越（Path Traversal）安全风险；
2. 校验 `winhttp.dll` 与各插件 DLL 是否为 x86（32 位）架构；
3. 列出将被覆盖的文件清单；
4. 将所有同名文件复制到带时间戳的备份目录中；
5. 解压合并后逐一校验 SHA-256 哈希值；
6. 启动游戏并确认日志的修改时间确实属于本次运行。

Mod 安装包可能残留旧的 `LogOutput.log`。判断框架是否正常运行，应综合比对日志修改时间、当前进程加载的模块以及 Chainloader 输出。

### 第一步：加载 Doorstop

在 `winecfg → Libraries` 中为游戏主程序添加配置：

```text
winhttp = native,builtin
```

优先使用仅作用于 `Mortal.exe` 的应用程序级 DLL override。运行游戏时，在进程中应能观察到已加载游戏目录下的 `winhttp.dll` 与 BepInEx Preloader。

### 第二步：提供匹配 Unity 版本的完整 corlibs

经比对，已验证游戏版本自带的 `Mortal_Data/Managed/mscorlib.dll` 大小为 `3,906,048` 字节；而匹配 Unity `2020.3.49f1` 的完整未裁剪版本（unstripped corlib）大小为 `4,065,792` 字节。

将合法获取、版本精准匹配的完整 corlibs 放入：

```text
BepInEx/unstripped_corlib/
```

编辑 `doorstop_config.ini`：

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

corlibs 必须与 Unity 引擎版本完全一致，并遵守 Unity 的软件许可协议。公开仓库与 Mod 分发包均保持零 corlibs 分发。

### 第三步：使用包含 Wine 修复补丁的 BepInEx 6

旧版 BepInEx 6 在 Wine 32 位环境下可能抛出以下异常：

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

该问题由 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201) 记录，并在 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) 中修复。已验证环境采用了包含该修复补丁的 x86 Mono 构建版本 `6.0.0-be.785`。替换前请完整备份 `BepInEx/core`。

成功加载时的日志特征：

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

随后应能看到各插件依次加载的记录。在已验证环境中，DiceMaster 与日文 Mod 的 5 个插件均已由 Chainloader 成功加载。DiceMaster 模组在 Wine 下同样受制于缺少 `winhttp` override、corlibs 裁剪与 BepInEx 初始化异常，通过本节的 Doorstop / corlibs / BepInEx Wine 修复路径同样可以完全修复。

## 6. 日常运维建议

- 建议关闭 Steam 全局游戏内嵌界面（Overlay）与《活侠传》的单独游戏内嵌界面，降低切换 App 窗口后的按键输入锁死概率。
- 游玩期间建议配合 `caffeinate` 防止系统休眠。若发生合盖休眠、锁屏或外接显示器热插拔，建议彻底重启游戏、Windows 版 Steam 与 wineserver 会话。
- Windows 版 Steam 长时间在后台挂起后，可能不再响应 `-applaunch` 启动指令。若 Steam `gameprocess_log.txt` 中无新增记录，请重启该 prefix 下的 Steam 与 Wine 会话。
- 退出游戏与 Steam 时，请使用 Windows 版 Steam 菜单中的 `Steam → Exit` 正常退出。macOS 程序坞（Dock）中的 Wine 图标仅为窗口代理。

## 7. 使用随仓库提供的只读检查脚本

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

该脚本仅以只读方式检查包装器配置、游戏架构、Steam 清单文件（manifest）、注册表设置、字体数量、DXMT 模块哈希值、BepInEx 日志以及当前运行的进程。它绝不会主动启动或结束 Wine、Steam 与游戏进程，亦不会修改任何文件。

## 参考资料

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [BepInEx Wine 修复补丁](https://github.com/BepInEx/BepInEx/pull/1254)
- [《活侠传》日文 Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
