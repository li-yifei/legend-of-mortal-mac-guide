# 案例：Wine 10 / x86 版《活侠传》加载日文 Mod

[返回简体中文指南](../guide.zhs.md) · [繁體中文](../guide.zht.md) · [日本語](japanese-mod.ja.md) · [한국어](japanese-mod.ko.md)

> 本文保留 2026-08-29、Build `20337760` 的旧版实测步骤，文中的 32 位组件选择对应这套配置。游戏 1.06（Build `25953419`）的 64 位入口修复见[1.06 升级案例](game-1.06.zhs.md)。新版功能的验证范围在该案例中分别列明。

本案例以日文 Mod v2.4 在 macOS Wine 环境下的排障过程为例，展示从故障排查、三步修复到最终验证与回滚保护的完整实践。

## 核心名词简释

| 名词 | 简要说明 |
| --- | --- |
| Doorstop | 启动引导工具，通过模拟系统 `winhttp.dll` 在游戏主程序加载时拦截入口并调用 Preloader。 |
| corlibs | Unity Mono 运行时的基础类库，分为裁剪后的 stripped 版本与完整未裁剪的 unstripped 版本。 |
| BepInEx | Unity 游戏的通用插件（Mod）加载与管理框架。 |
| Preloader | BepInEx 的预加载器，在游戏主逻辑运行前初始化环境并准备必要依赖。 |
| Chainloader | BepInEx 的链式加载器，负责按序加载 `BepInEx/plugins/` 目录中的各个具体插件。 |

## 验证条件

| 项目 | 条件 |
| --- | --- |
| 游戏 | Steam AppID `1859910`，Build ID `20337760` |
| Unity | `2020.3.49f1` |
| 进程架构 | `Mortal.exe`，PE32 / x86 |
| Wine | Sikarugir Wine `10.0` |
| Mod | [日文 Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/) |
| 原 BepInEx | `6.0.0-be.692` |
| 验证可用版本 | `6.0.0-be.785` x86 Mono |
| 验证日期 | 2026-08-29 |

## 1. 遇到问题与压缩包安全性检查

将日文 Mod v2.4 解压放入游戏目录后，游戏虽能启动，但日文翻译完全未生效。查看日志发现加载流程在进入 Chainloader 初始化前便已静默中断。

在安装与排查前，对 Mod 压缩包执行了安全性检查：
1. 校验 ZIP 压缩包的完整性，排除损坏风险。
2. 检查压缩包内路径，排除绝对路径与 `..` 路径穿越风险。
3. 确认压缩包内的原生 DLL 满足 32 位（x86）架构要求。
4. 将所有同名现有文件备份至带时间戳的独立目录中。
5. 解压合并后校验文件哈希值，确认原有的 DiceMaster DLL 及配置文件保持完整。

## 2. 三步修复流程与原因分析

### 第一步：加载 Doorstop（解决入口未拦截问题）

原因分析：Wine 默认使用内置的 `winhttp.dll`，导致游戏启动时不会加载游戏目录中用于引导 Mod 的伪装 `winhttp.dll`。

操作方法：在 `winecfg` 的函数库（Libraries）设置中，为 `Mortal.exe` 单独添加应用程序级 DLL override：

```text
winhttp = native,builtin
```

效果：进程成功加载游戏本地的 `winhttp.dll` 并启动 Preloader。但此时加载流程依然在 Chainloader 之前中断，表明托管入口存在后续阻碍。

### 第二步：补充匹配 Unity 版本的完整 corlibs（解决基础类库缺失问题）

原因分析：游戏自带的 Mono 类库为裁剪版，缺少 BepInEx 初始化所需的完整 API 签名支持。

```text
游戏自带 mscorlib.dll       3,906,048 bytes
Unity 2020.3.49 完整版       4,065,792 bytes
```

操作方法：通过合法途径获取与游戏 Unity `2020.3.49f1` 精确匹配的完整未裁剪 corlibs，放入 `BepInEx/unstripped_corlib/` 目录，并在 `doorstop_config.ini` 中指定搜索路径：

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

效果：Preloader 成功执行并输出 `Done`。corlibs 必须严格匹配 Unity 引擎版本，并遵守 Unity 软件许可协议。

### 第三步：更新为包含 Wine 修复的 BepInEx 6（解决平台判断异常）

原因分析：旧版 BepInEx `6.0.0-be.692` 在 Wine 32 位环境下初始化平台辅助类时抛出异常：

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

该问题记录于 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)，并在 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) 中修复。

操作方法：完整备份现有的 `BepInEx/core` 目录后，将其替换为包含该 PR 修复的 x86 Mono 构建版本 `6.0.0-be.785`。入口点保持为默认的 `Application::.cctor`。

## 3. 验证成功与插件运行状态

完成上述三项修复后重新启动游戏，Mod 框架与各插件成功加载。

框架就绪日志：

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

成功加载的插件清单：

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

运行验证结果：
- Chainloader 成功加载了 5 个插件；
- 日志报告确认注入了 72,977 行日文文本；
- 日志中未出现新的 Error 或 Fatal 级别报错；
- 游戏内语言设置为“简体中文”即可显示日文字幕；
- 游戏中可按 `F5` 切换姓名振假名显示，按 `F7` 切换显示模式；
- 在本测试环境中，DiceMaster 模组因同样受制于缺失 winhttp 覆盖、corlibs 裁剪与 BepInEx 初始化异常，通过同一套修复路径亦能恢复正常加载。

### 历史环境实测总结

| 验证项目 | 历史配置与条件 | 结果 | 证据与记录 | 置信度 |
| --- | --- | --- | --- | --- |
| 日文 Mod v2.4 加载 | Build `20337760`，Wine `10.0`，x86 PE32 | 5 个插件全部正常加载 | BepInEx 日志输出 Chainloader initialized 与 72,977 行文本注入 | 高 |
| DiceMaster 模组加载 | 同上测试环境与修复流程 | 插件成功加载并初始化 | 日志输出 `DiceMaster 1.0.0` 且无异常退出 | 高 |

## 4. 回滚与安全边界

为确保能够安全恢复，维护 3 个独立阶段的备份：
1. **Mod 合并前备份**：保留纯净游戏目录；
2. **corlibs 配置前备份**：保留原始 `doorstop_config.ini`；
3. **be.785 替换前备份**：保留原始 `BepInEx/core` 目录。

回滚执行要求：在还原任何文件前，必须先在游戏内保存并彻底退出游戏、Windows 版 Steam 以及当前包装器的 wineserver 进程。还原时请成套恢复同一阶段的文件，避免混用不同 BepInEx 构建版本的核心 DLL。
