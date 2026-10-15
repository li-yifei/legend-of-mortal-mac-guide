# 在 Apple Silicon Mac 上运行《活侠传》：安装、字体与 Mod 修复

[返回首页](../README.md) · [繁體中文](guide.zht.md) · [日本語](guide.ja.md) · [한국어](guide.ko.md)

> 本文保留 2026-08-29、Build `20337760` 的旧版实测步骤，文中的 32 位组件选择对应这套配置。游戏 1.06（Build `25953419`）的 64 位入口修复见[1.06 升级案例](cases/game-1.06.zhs.md)。新版功能的验证范围在该案例中分别列明。

本指南面向希望在 Apple Silicon Mac 上游玩自购正版《活侠传》的玩家，介绍如何借助 Sikarugir、Wine 与 Windows 版 Steam 完成安装，并排查图形初始化、商店文字缺失与 Mod 无法加载等常见问题。

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
| 最近验证日期 | 2026-08-29 |

Wine、Steam、macOS 与游戏本身的更新均可能影响兼容性与运行结果。在进行任何配置调整时，请记录版本号并创建带时间戳的备份。

## 常见症状速查

各修复章节仅在遇到对应症状时按需执行。若游戏运行正常，无需执行额外修复。

| 遇到症状或需求 | 对应章节 | 核心操作 |
| --- | --- | --- |
| 首次安装与配置环境 | [1. 建立独立的 Windows 版 Steam 包装器](#install) | 创建包装器、安装 Windows Steam 与游戏 |
| 启动闪退 / 提示 D3D11 错误 | [2. 修复 D3D11 图形初始化失败](#graphics) | 启用 DXMT 图形转换（必要时手动替换 Engine DLL） |
| 画面模糊拉伸或 UI 过小 | [3. Retina 与分辨率设置](#retina) | 按需要开启 RetinaMode，自选窗口分辨率 |
| 商店界面单价与总计金额空白 | [4. 修复商店价格与总额显示空白](#fonts) | 备份注册表并通过 Winetricks 安装 allfonts 字体库 |
| Mod 或日文补丁未生效 / 报错 | [5. 修复 Doorstop 与 BepInEx Mod 加载](#mods) | 配置 winhttp 覆盖、补充完整 corlibs、更新 BepInEx 核心 |
| 切换窗口后键盘鼠标无响应 | [6. 已知问题](#focus) | 单击窗口顶部深色标题栏恢复焦点控制 |
| 游戏长期挂起或系统休眠防崩 | [7. 日常运维建议](#daily) | 关闭 Overlay，使用 caffeinate，规范退出 Steam |
| 诊断当前环境配置与日志 | [8. 使用随仓库提供的只读检查脚本](#diagnostics) | 运行只读检查脚本输出环境报告 |

## 核心名词简释

| 名词 | 简要说明 |
| --- | --- |
| 包装器（Wrapper / App） | macOS 下后缀为 `.app` 的应用程序包，封装了 Wine 运行环境与 Windows 程序。 |
| Wine | 让 Windows 程序在 macOS 上调用所需系统功能的兼容层。 |
| Wine prefix | 包装器内部模拟的 Windows 系统环境（包含虚拟 C 盘文件结构与注册表）。 |
| Winetricks | 用于向 Wine prefix 自动化安装 Windows 常用运行库与字体的辅助脚本工具。 |
| DXMT | 将 Windows 的 Direct3D 11 图形渲染指令翻译为 Apple Metal 指令的转换层。 |
| BepInEx | 广泛用于 Unity 引擎游戏的 Mod 插件加载与管理框架。 |
| Doorstop / 引导链 | Mod 加载的入口引导工具。Doorstop 截获启动并调用 Preloader 准备环境，再由 Chainloader 载入具体 Mod 插件。 |

<a id="install"></a>

## 1. 建立独立的 Windows 版 Steam 包装器

准备工作：
- Apple Silicon Mac 与 macOS 14 或更高版本；
- Rosetta 2 环境；
- [Sikarugir 官方项目](https://github.com/Sikarugir-App/Sikarugir)；
- 个人 Steam 账户中已购买的 [《活侠传》](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)；
- 足够的磁盘空间（用于存放包装器、Steam、游戏本体与各阶段备份）。

使用 Sikarugir Creator 创建独立包装器（例如 `SteamWin.app`）。在包装器专属的 Wine prefix 中依次完成以下操作：

1. 初始化 Wine prefix，确认已同时生成 `Program Files` 与 `Program Files (x86)` 目录。
2. 通过 Winetricks 安装 `cjkfonts`。
3. 应用注册表设置 `hidewineexports=enable`。
4. 安装 Windows 版 Steam。
5. 将启动目标设为 `C:\Program Files (x86)\Steam\steam.exe`。
6. 登录 Steam 并下载安装 AppID `1859910`。

macOS 原生 Steam 与 Windows 版 Steam 可以共存。如遇登录或网络连接异常，请先彻底退出另一端的客户端，避免同一账号的会话发生冲突或被强制下线。

### 检查游戏主程序架构

Steam 商店页面的系统要求无法替代实际的文件架构检查。请在 macOS 终端中运行以下命令（其中 `/path/to/...` 为占位符，请替换为游戏在您 Mac 硬盘上的实际安装路径）：

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
```

实测构建版本（Build）的检查结果：

```text
PE32 executable (GUI) Intel 80386, for MS Windows
```

检查结果显示为 PE32（32 位 x86 架构）。在这套旧版配置中，原生入口 DLL 和图形模块要匹配 `Mortal.exe` 的 32 位架构。托管 Mod 插件可能同时支持 32 位和 64 位，具体取决于插件的编译设置、依赖和 Unity 兼容性。后续修复按遇到的症状执行。

<a id="graphics"></a>

## 2. 修复 D3D11 图形初始化失败

### 故障症状与常规启用

典型症状：Steam 短暂显示“运行中”后游戏异常退出；弹出错误窗口或在 `Player.log` 中记录：

```text
Failed to initialize graphics.
InitializeEngineGraphics failed
d3d11: failed to create device and context (80004005)
```

常规启用操作：
1. 打开包装器设置界面。
2. 在图形设置中开启 DXMT 开关。
3. 启动游戏验证是否能正常进入主界面。

### 进阶排查：Engine DLL 手动替换回退方案

若界面开启 DXMT 后仍出现初始化错误，需通过日志核验 DXMT 是否真正生效。只有在确认系统未能加载 DXMT 模块时，才执行本 Engine 层级的回退替换方案。

替换步骤：
1. 查看 `WINEDEBUG=+loaddll` 日志，确认当前生效 Engine 的真实模块目录。
2. 备份原有的 32 位 WineD3D 模块，并记录原始文件的 SHA-256 哈希值。
3. 将对应版本的 DXMT 模块（`d3d10core.dll`、`d3d11.dll`、`dxgi.dll`、`winemetal.dll`）复制放入实际生效的 `i386-windows` 目录。
4. 将匹配的 `winemetal.so` 放入对应的 Unix 模块目录。
5. 记录替换后各文件的 SHA-256 哈希值，确保版本精确匹配。

<details markdown="1">
<summary>图形渲染后端对比与成功加载日志</summary>

在已验证构建版本中测试各类图形后端的表现：
- Unity OpenGL：游戏本身缺少对应的图形设备（Graphics Device）支持。
- WineD3D + MoltenVK：虽能识别 Apple GPU，但在 Direct3D 功能级别（Feature Level）协商阶段失败。
- D3DMetal：主要覆盖 64 位的 D3D11/D3D12，无法直接用于 32 位游戏。
- DXMT：提供完整的 32 位 D3D10/11 模块，适配当前 32 位（PE32）游戏。

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

</details>

日常启动建议使用 Steam AppID 命令行参数：

```text
steam.exe -applaunch 1859910
```

<a id="retina"></a>

## 3. Retina 与分辨率设置

Wine Retina 模式对应的注册表路径：

```text
HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"
```

Retina 渲染与 Unity UI 缩放是相互独立的机制。《活侠传》的 Unity UI 逻辑基本忽略 Windows DPI 设置。高分辨率能提供更清晰细腻的画面，但 UI 相对偏小；较低分辨率下 UI 尺寸较大，但会有拉伸模糊现象。

建议让游戏记住用户自行选择的窗口分辨率。已验证环境采用 `1920×1200`，并在桌面快捷方式的启动参数中移除了强制的 `-screen-width` 与 `-screen-height` 参数。

<a id="fonts"></a>

## 4. 修复商店价格与总额显示空白

### 故障症状与修复操作

典型症状：游戏内的中文对话、常规数值与铜钱图标均能正常显示，但商店界面中的商品单价与总计金额显示为空白。

修复操作：
1. 彻底退出 Windows 版 Steam。
2. 完整备份以下 4 处文件与目录：
   - `drive_c/windows/Fonts`
   - `system.reg`
   - `user.reg`
   - `userdef.reg`
3. 打开 Winetricks，选择并安装：
```text
fonts → allfonts
```
4. 退出并重新启动当前包装器，安全重启其专用的 wineserver 会话。
5. 启动游戏验证商店金额是否正常显示。

<details markdown="1">
<summary>字体缺失原因与测试观察记录</summary>

经 Unity 资源检查确认，`MoneyValue` 与 `MoneyText` UI 组件绑定了内嵌字体 `SourceHanSerifTC-Bold`；其默认文本包含 `50`，字体图集中也完整包含 `0–9` 数字字符。问题根源在于 Wine prefix 中的字体集合与系统字体映射不完整。

初始创建的 prefix 仅包含：

```text
sourcehansans.ttc
unifont.ttf
```

实测安装 `allfonts` 后，测试环境的字体目录由 2 个文件增加到 121 个（约 284 MB），Arial、Tahoma、Calibri、Meiryo 与 WenQuanYi 等字体的注册表项均已写入。该文件数量与体积为实测环境记录，各环境的实际数量可能有所浮动。

各类字体均有其独立的软件许可协议。请通过 Winetricks 从原始来源下载安装，公开仓库与预打包包装器保持零字体分发。

</details>

<a id="mods"></a>

## 5. 修复 Doorstop 与 BepInEx Mod 加载

详细排障过程请参见案例分析：[案例：Wine 10 / x86 版《活侠传》加载日文 Mod](cases/japanese-mod.zhs.md)。

### Mod 启动原理与架构要求

Mod 框架的引导流程分为三个阶段：
1. **Doorstop 介入**：通过伪装的 `winhttp.dll` 在游戏启动时接管入口，加载 Preloader。
2. **Preloader 准备**：加载 Unity 基础程序集（corlibs）并初始化环境。
3. **Chainloader 启动**：链式加载器就绪后，依次载入 `BepInEx/plugins/` 目录下的各 Mod 插件。

架构匹配规则：作为原生入口的 `winhttp.dll` 必须与历史验证构建版本的 32 位（PE32）可执行文件保持一致；位于插件目录的托管 DLL（C# 编译程序集）可具备架构中立性，但须符合插件自身针对 Unity 版本的兼容要求。

### 安装 Mod 前的备份与检查流程

对每个 Mod 压缩包依次执行以下检查：
1. 检查压缩包内路径，排除绝对路径与 `..` 路径穿越安全风险。
2. 校验 `winhttp.dll` 与原生 DLL 是否为 x86（32 位）架构。
3. 列出将被覆盖的文件清单。
4. 将所有同名文件复制到带时间戳的备份目录中。
5. 解压合并后逐一校验 SHA-256 哈希值。
6. 启动游戏并确认 `LogOutput.log` 的修改时间与本次运行完全一致（避免误读压缩包内残留的历史日志）。

### 第一步：加载 Doorstop

在 `winecfg → Libraries` 中为游戏主程序添加配置：

```text
winhttp = native,builtin
```

优先使用仅作用于 `Mortal.exe` 的应用程序级 DLL override。运行游戏时，在进程中应能观察到已加载游戏目录下的 `winhttp.dll` 与 BepInEx Preloader。

### 第二步：提供匹配 Unity 版本的完整 corlibs

游戏自带的 `Mortal_Data/Managed/mscorlib.dll` 为裁剪版本（大小为 `3,906,048` 字节）；而匹配 Unity `2020.3.49f1` 的完整未裁剪版本（unstripped corlib）大小为 `4,065,792` 字节。

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

替换前请完整备份 `BepInEx/core` 目录。将核心文件替换为包含 PR #1254 修复补丁的 x86 Mono 构建版本 `6.0.0-be.785`。

验证加载成功的日志特征：

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

日志中出现 `Chainloader initialized` 表明 Mod 框架初始化成功；随后各插件将输出各自的加载信息。在已验证历史配置中，DiceMaster 同样受制于缺失 `winhttp` override、corlibs 裁剪与 BepInEx 初始化异常，通过本节相同的 Doorstop / corlibs / BepInEx Wine 修复路径能够成功加载运行（该结论仅适用于已验证的历史构建版本组合，不代表支持所有功能与后续版本）。

<details markdown="1">
<summary>BepInEx 异常详情与修复补丁来源</summary>

旧版 BepInEx 6 在 Wine 32 位环境下可能抛出以下异常：

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

该问题由 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201) 记录，并在 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) 中修复。

</details>

<a id="focus"></a>

## 6. 已知问题

### 切换窗口后需点击标题栏恢复控制

故障表现：在已验证的环境中，从游戏切换到其他 macOS 应用再切回《活侠传》后，游戏画面正常刷新，但键盘、鼠标或手柄输入可能无法在游戏内响应。

实测有效的恢复操作：
1. 切回《活侠传》的 `Mortal` 游戏窗口。
2. 单击窗口顶部的 macOS 标题栏（即下图中红色箭头所指的深色区域）一次。
3. 返回游戏画面继续操作。

![单击 Mortal 窗口标题栏以恢复游戏输入](assets/window-titlebar-focus-recovery.png)

关闭 Steam 全局 Overlay 与《活侠传》的单独 Overlay 可降低出现频率。单击标题栏是当前已验证的高置信度即时恢复方案。该问题的底层根因仍在排查中，符合 Wine、Unity 与 macOS 之间窗口焦点传递异常的特征。

| 游戏版本 | 触发条件 | 结果 | 证据 | 置信度 |
| --- | --- | --- | --- | --- |
| Build `20337760` / `release_1.0.5000.13` | 从其他 macOS App 切回 Wine 游戏窗口 | 单击 `Mortal` 标题栏后恢复游戏控制 | 实机复现与截图 | 高 |

<a id="daily"></a>

## 7. 日常运维建议

- 关闭 Steam 全局游戏内嵌界面（Overlay）与《活侠传》的单独游戏内嵌界面，降低切换应用窗口后的按键输入锁死概率。
- 游玩期间建议配合 `caffeinate` 防止系统休眠。若发生合盖休眠、锁屏或外接显示器插拔，建议在保存游戏后彻底退出并重启游戏、Windows 版 Steam 与对应包装器会话。
- 退出游戏与 Steam 时，请先在游戏内保存退出，再使用 Windows 版 Steam 菜单中的 `Steam → Exit` 正常退出。macOS 程序坞（Dock）中的 Wine 图标仅为窗口代理。
- 重启 Wine 时，先保存并退出游戏，再只重启本游戏包装器的会话。
- Windows 版 Steam 长时间在后台挂起后，可能不再响应 `-applaunch` 启动指令。若 Steam `gameprocess_log.txt` 中无新增记录，请重启该包装器下的 Steam 与 Wine 会话。

<a id="diagnostics"></a>

## 8. 使用随仓库提供的只读检查脚本

```bash
skills/run-legend-of-mortal-on-mac/scripts/inspect-lom-wrapper.sh \
  "/path/to/SteamWin.app"
```

该脚本仅以只读方式检查包装器配置、游戏架构、Steam 清单文件（manifest）、注册表设置、字体数量、DXMT 模块哈希值、BepInEx 日志以及当前运行的进程（其中 `/path/to/SteamWin.app` 为占位符，请替换为包装器的实际路径）。该脚本不会启动或结束 Wine、Steam 与游戏进程，亦不会修改任何系统或游戏文件。

## 参考资料

- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [BepInEx Wine 修复补丁](https://github.com/BepInEx/BepInEx/pull/1254)
- [《活侠传》日文 Mod](https://dlaqe2334.github.io/LOM-JPMOD/)
