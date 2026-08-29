# 案例：Wine 10 / x86 版《活侠传》加载日文 Mod

[返回简体中文指南](../guide.zhs.md) · [繁體中文](../guide.zht.md) · [日本語](japanese-mod.ja.md) · [한국어](japanese-mod.ko.md)

## 结论

日文 Mod v2.4 的各类文件虽已正确放置到游戏目录中，但插件加载流程在进入 Chainloader 初始化之前便已中断。最终实现正常运行的配置如下：

- 仅针对 `Mortal.exe` 设置的应用程序级 DLL override：`winhttp = native,builtin`；
- 与 Unity `2020.3.49f1` 版本完全匹配的完整未裁剪 corlibs；
- 优先搜索 `BepInEx/unstripped_corlib` 的 Doorstop 配置；
- 包含 BepInEx Wine 初始化修复补丁（PR #1254）的 x86 Mono 构建版本 `6.0.0-be.785`；
- BepInEx 默认托管入口点（`Application::.cctor`）；
- 游戏内语言设置为“简体中文”。

修复后，Chainloader 成功加载了 5 个插件，并注入了 72,977 行日文文本。原本在此环境下失效的 DiceMaster 模组，通过相同的 Doorstop / corlibs / BepInEx Wine 修复路径（即应用程序级 DLL override、匹配的完整 Unity corlibs 与修复版 BepInEx 核心）也同样得到了修复并正常加载。

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

## 1. 压缩包安全性检查

在安装前对 ZIP 压缩包的完整性、绝对路径、`..` 路径穿越风险、外层目录结构、原生 DLL 的 x86 兼容性以及与现有文件的冲突进行了全面检查。在首次下载时，由于混用了不同的断点续传方式导致 Central Directory 损坏；后续重新使用单一下载器获取了完整的 ZIP 压缩包并校验通过。

将所有需要覆盖的现有文件备份至带时间戳的目录中，在合并后重新校验了文件哈希值，确认原有的 DiceMaster DLL 及配置文件哈希值保持完整。

## 2. 加载 Doorstop

在 `winecfg` 的函数库（Libraries）设置中，为 `Mortal.exe` 添加应用程序专属的 DLL override：

```text
winhttp = native,builtin
```

此设置使进程成功加载本地的 `winhttp.dll` 与 Preloader。但此时加载流程依然停留在 Chainloader 初始化之前，表明下一个阻塞点位于托管入口端。

## 3. 使用完整的 Unity corlibs

```text
游戏自带 mscorlib.dll       3,906,048 bytes
Unity 2020.3.49 完整版       4,065,792 bytes
```

通过正规渠道获取与游戏 Unity 版本完全一致的完整 corlibs，放入 `BepInEx/unstripped_corlib/` 目录，并配置 `doorstop_config.ini`：

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

在详细日志中确认了 Preloader 的调用及 `Done` 输出。corlibs 必须严格匹配 Unity 版本，并在遵守 Unity 许可协议的前提下获取与使用。

## 4. 修复 BepInEx 的 Wine 初始化异常

Preloader 执行后触发了以下异常：

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

这是 BepInEx 在 Wine/Proton 环境下初始化阶段的已知问题：

- [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)
- [修复补丁 PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)

在完整备份原有的 `BepInEx/core` 后，将其整体替换为包含 PR #1254 修复的 x86 Mono 构建版本 `6.0.0-be.785`。入口点恢复为默认的 `Application::.cctor`。

## 5. 最终验证

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

成功加载的插件列表：

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

DiceMaster 及日文 Mod 插件群（共 5 个）均已由 Chainloader 成功加载，日文字库完成 72,977 行文本注入，且日志中未产生新的 Error/Fatal 报错。无论是单独使用 DiceMaster 还是与日文 Mod 共同使用，其在 macOS / Wine 环境下遇到的底层阻碍（Doorstop 未加载、corlibs 裁剪导致 Preloader 静默中断、BepInEx 平台初始化异常）完全一致，因此均可通过同一套 Doorstop / corlibs / BepInEx Wine 修复路径恢复正常运行。游戏内语言请选择“简体中文”；游戏中可按 `F5` 切换姓名振假名，按 `F7` 切换显示模式。

## 6. 回滚边界

维护 3 个独立阶段的备份：Mod 合并前、corlibs 配置前以及 `be.785` 替换前。在执行回滚操作时，请确保游戏、Windows 版 Steam 及对应包装器的 wineserver 已完全退出，并成套恢复同一层的文件。切勿混用来自不同 BepInEx 构建版本的 core DLL。
