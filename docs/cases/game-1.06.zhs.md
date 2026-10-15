---
layout: page
title: "《活侠传》1.06 更新后 Mod 失效：先检查 64 位入口"
permalink: /docs/cases/game-1.06.zhs/
---

[返回简体中文指南](../guide.zhs.md) · [繁體中文](game-1.06.zht.md) · [日本語](game-1.06.ja.md) · [한국어](game-1.06.ko.md)

2026 年 10 月 15 日实测：更新到游戏 1.06、Steam Build `25953419` 后，游戏可以启动，DiceMaster 和存档扩展却没有效果。检查发现，游戏主程序已从 32 位升级为 64 位，而负责把 Mod 框架注入游戏的 Doorstop 入口工具仍停留在旧的 32 位版本。

本次换用 Doorstop `4.4.0` 的 Windows x64 `winhttp.dll`，保留原有 BepInEx `6.0.0-be.785`、DiceMaster `1.0.0` 和存档扩展 `1.2.0`，随后恢复了插件加载。存档扩展已有玩家确认可用，DiceMaster 的选项收益提示已有截图确认显示。**日文 Mod 在 1.06 下的兼容性仍待单独验证。**

## 先判断是否属于这个问题

适合参考本案例的情况是：游戏更新后可以进入主菜单，但原本可用的 Mod 同时失效。若曾按照旧版指南安装过 32 位 Doorstop，应优先检查游戏主程序与入口 DLL 的位数。

| 要检查的文件 | 本次更新后的实际结果 | 含义 |
| --- | --- | --- |
| `Mortal.exe`、`UnityPlayer.dll` | PE32+ / x86-64 | 游戏主程序已变为 64 位 |
| 原有 `winhttp.dll` | PE32 / x86 | 仍是旧的 32 位 Doorstop 入口，需要更换 |
| BepInEx、DiceMaster、存档扩展 | 托管程序集（.NET DLL），未设置 `Requires32Bit` | 本次保留后已在 64 位游戏中正常加载；切勿因为游戏换架构就盲目替换托管核心 |

Doorstop 使用游戏目录里的 `winhttp.dll` 在启动时加载 BepInEx（Unity Mod 框架）；BepInEx 再加载各个 Mod。原生 DLL 必须与 `Mortal.exe` 匹配位数，而托管插件（C# 编写的 Mod 程序集）则需结合其自身兼容性与实际功能进行验证，不必全盘更换。

## 修复顺序

### 1. 退出游戏并备份

正常存档并退出游戏，再退出包装器（Wrapper，即 macOS 上的 Wine 运行环境）内的 Windows 版 Steam。若需要结束 Wine 会话，只处理本游戏所在的包装器。

备份游戏目录中的 `winhttp.dll`、`doorstop_config.ini` 和完整 `BepInEx` 目录；记录文件版本和 SHA-256 哈希值。需要同时升级运行组件时，再单独备份整个包装器。本次实测使用了完整包装器备份。

### 2. 确认游戏和 DLL 的位数

在 macOS 终端中运行下面两条只读命令。将 `/path/to/LegendOfMortal` 替换为自己游戏目录的完整路径。

```bash
file "/path/to/LegendOfMortal/Mortal.exe"
file "/path/to/LegendOfMortal/winhttp.dll"
```

本次修复前，游戏主程序显示 `PE32+` / `x86-64`（64 位），而 `winhttp.dll` 显示 `PE32` / `Intel 80386`（32 位）。这个位数差异是本次入口注入失效的原因。

### 3. 更换为 Windows x64 Doorstop

从 [UnityDoorstop 4.4.0 官方发布页](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0) 获取 Windows 版本，解压后核对 x64 `winhttp.dll`，再替换游戏根目录中的同名文件。通过 Wine 运行的游戏必须使用 Windows 版 DLL。

这次保留了原有 `doorstop_config.ini`、完整 corlibs（Unity 核心依赖库）和 BepInEx 托管核心。原有 BepInEx、DiceMaster 和存档扩展都没有设置强制 32 位标记，最终在这次 64 位启动中成功加载。切勿因为游戏架构变化而盲目替换托管核心。其他版本的插件仍需逐个核验。

在包装器的 `winecfg` 中，先在 **Applications** 标签页选择 `Mortal.exe`，再到 **Libraries** 标签页确认该游戏专用设置：

```text
winhttp = native,builtin
```

它让 Wine 优先使用游戏目录里的 Doorstop 原生文件。Unity 引擎版本未变，仍为 `2020.3.49f1`，本次继续沿用匹配该版本的 corlibs。游戏更新后，Unity 版本也应重新核对。

### 4. 用本次启动的日志检查加载

启动游戏后，确认 `BepInEx/LogOutput.log` 的修改时间晚于本次游戏启动时间。旧日志曾在这次排查中造成误判：日志停在 16:12，而游戏已于 16:14 重新启动。

修复后在 16:25 的启动日志包含：

```text
Process bitness: 64-bit (x64)
Chainloader initialized
Loading [DiceMaster 1.0.0]
Loading [LOM Save Slot Expander 1.2.0]
Chainloader startup complete
```

`Process bitness: 64-bit (x64)` 确认当前进程为 64 位；`Chainloader initialized` 确认框架已启动；每个 `Loading [...]` 条目确认对应插件已进入加载流程。最后还要在游戏内实际检查各项功能。

## 本次验证到了哪里

### 日文 Mod v2.5 的补充

同日更新的日文 Mod v2.5 已完成包内静态分析：安装包内置了 64 位 Doorstop（版本标记 `4.3.0`）、分版本管理的运行组件与翻译数据，以及新的排版处理。但包内 BepInEx 核心仍为 `be.692`，若直接整包覆盖，会替换掉本机已验证可用的 `be.785`。建议玩家在尝试前先完整备份现有环境，再逐步确认框架初始化、新插件加载与日文显示。需要说明的是，本案例中 Doorstop `4.4.0` 的启动记录属于本机独立修复，不能当作 v2.5 的运行证据；v2.5 在 macOS 下的实际运行表现仍待验证。

### 已确认与待验证项目

| 项目 | 条件与结果 | 证据与置信度 |
| --- | --- | --- |
| 游戏与 Mod 框架启动 | Build `25953419`、x64 Doorstop、新日志显示 x64 与 Chainloader 完成 | 当前进程模块和本次启动日志；高 |
| 存档扩展 `1.2.0` | 玩家确认存档扩展功能可用 | 玩家实际操作确认；高，仅限已确认功能 |
| DiceMaster `1.0.0` 选项信息 | 选项收益提示恢复显示 | 玩家游戏截图；高，仅限提示显示；数值准确性与新剧情解析待验证 |
| DiceMaster 菜单 | 本机快捷键配置为 `F10`（本地自定义快捷键，非通用默认快捷键），内置键盘可用 `Fn + F10` | 本地快捷键配置已确认，菜单交互待验证 |
| 日文 Mod | 1.06 环境下未进行测试 | 待验证 |
| 字体外观、窗口切换、睡眠唤醒、长时间游玩 | 本轮只完成启动、图形与音频初始化检查 | 待后续游玩验证；旧版结论保留在历史指南中 |

验证 DiceMaster 时，建议选择一个收益明确的新剧情选项，比对选择前后的实际属性变化；并测试一个新骰点事件及对应分支。提示能否正常显示、数值是否准确、骰点控制是否生效，属于需要分别确认的不同项。本轮验证尚未确认新剧情解析、数值准确性、骰点控制、特殊结算以及 F10 菜单交互的完整兼容性。

## 同时升级的运行组件

以下是本机最终采用的组件组合，验证日期为 2026 年 10 月 15 日。修复入口和升级运行组件分别记录，便于判断每次改动的具体影响。

| 组件 | 本次最终配置 |
| --- | --- |
| 游戏 | Steam AppID `1859910`、Build `25953419`、x64 |
| Unity | `2020.3.49f1` |
| Doorstop | `4.4.0` Windows x64 |
| BepInEx | 保留 `6.0.0-be.785` 托管核心 |
| Sikarugir Creator | `1.0.2` |
| 包装器运行组件 | Template `1.0.22` |
| Wine 引擎 | Sikarugir `10.0 revision 8` |
| DXMT | 新模板配套构建 `v0.80-244-g7c8dee1` |

Steam 登录、游戏启动、D3D11 feature level 11.1、音频初始化与场景加载均通过。Wine 11.0 revision 1 在本机原有环境和新建空环境中都卡在 `wineboot` 初始化，原因仍待排查，属于本机特定未决问题；本机最终采用验证通过的 Wine 10.0 revision 8。这项观察仅适用于本次测试环境。

## 需要回退时

先正常退出游戏、Windows 版 Steam 和本包装器的 Wine 会话，再恢复对应层的备份。例如只更换了 Doorstop，就恢复之前的 `winhttp.dll`；更换了运行组件，就按成套备份恢复该层组件。

完整包装器备份也包含备份时的存档。若在备份后继续游玩并产生了新进度，恢复整套环境前务必单独备份新存档，以免游戏进度被旧存档覆盖，并核对存档与游戏版本的兼容性。恢复 BepInEx 托管核心时按完整构建成组处理。

## 官方来源

- [UnityDoorstop 4.4.0](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0)
- [Sikarugir Creator 1.0.2](https://github.com/Sikarugir-App/Creator/releases/tag/v1.0.2)
- [Sikarugir Template 发布页](https://github.com/Sikarugir-App/Template/releases/tag/v1.0)
- [Sikarugir Engines 发布页](https://github.com/Sikarugir-App/Engines/releases/tag/v1.0)

本文依据 2026 年 10 月 15 日的本机升级记录、本次启动日志和玩家确认整理。原始记录中的个人路径、账号信息与存档均保存在本地。
