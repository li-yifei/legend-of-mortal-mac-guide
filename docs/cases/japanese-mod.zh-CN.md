# 案例：在 Wine 10 / x86《活侠传》中修复日语 Mod 加载

[返回中文指南](../guide.zh-CN.md) · [日本語](japanese-mod.ja.md) · [한국어](japanese-mod.ko.md)

## 案例结论

《活侠传》日文 Mod v2.4 的文件已经正确合并到游戏目录，插件最初仍然没有进入 Chainloader。最终生效的组合是：

- `Mortal.exe` 应用级 `winhttp = native,builtin`；
- Unity `2020.3.49f1` 匹配的完整 corlibs；
- `doorstop_config.ini` 优先搜索 `BepInEx/unstripped_corlib`；
- 包含 BepInEx Wine 初始化修复 PR #1254 的 x86 Mono `6.0.0-be.785`；
- BepInEx 默认 `Application::.cctor` 入口；
- 游戏内语言设置为“简体中文”。

修复后，BepInEx 识别 Wine 10.0 与 32 位游戏进程，Chainloader 加载 5 个插件，日文字库注入 72,977 行文本。DiceMaster 长期失效的问题也在同一修复中解决。

## 适用环境

| 项目 | 本案例条件 |
| --- | --- |
| 游戏 | Steam AppID `1859910`，Build ID `20337760` |
| Unity | `2020.3.49f1` |
| 游戏架构 | `Mortal.exe`，PE32 / x86 |
| 包装器 | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| Mod | [《活侠传》日文 Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/) |
| 原框架 | BepInEx `6.0.0-be.692` x86 Mono |
| 最终框架 | BepInEx `6.0.0-be.785` x86 Mono |
| 验证日期 | 2026-08-29 |

这个结论绑定上述版本。游戏、Mod、BepInEx 或 Wine 更新后应重新验证。

## 一、安装包检查与安全合并

日文 Mod 采用“把 ZIP 内容覆盖到游戏根目录”的安装方式。正式写入前执行了以下检查：

1. 使用单一下载器取得完整 ZIP；
2. 运行 ZIP 完整性测试；
3. 检查绝对路径、`..` 与外层目录；
4. 确认 `winhttp.dll`、BepInEx 和插件 DLL 与 PE32 游戏兼容；
5. 计算与现有 BepInEx、Doorstop、DiceMaster 的文件冲突；
6. 备份完整入口文件和现有 BepInEx；
7. 合并后逐项核对文件哈希。

第一次下载曾混用两种断点续传方式，产生了尺寸异常、中央目录损坏的 ZIP。完整性检查阻止了该文件进入游戏目录。重新使用单一下载器后，ZIP 校验通过。

包内多了一层外部目录，安装时需要把真正的游戏根目录内容合并到：

```text
LegendOfMortal/
├── BepInEx/
├── doorstop_config.ini
├── winhttp.dll
└── Mortal.exe
```

冲突对比显示，日文 Mod v2.4 附带的 BepInEx 核心与当时已有核心逐文件一致；DiceMaster DLL 与配置保持原哈希。合并阶段没有破坏已有 Mod。

## 二、旧 `LogOutput.log` 造成的误判

游戏目录中已经存在：

```text
BepInEx/LogOutput.log
```

日志内容包含 DiceMaster 加载记录，看起来像 BepInEx 已经成功注入。文件修改时间显示它来自 2024 年，是安装包携带的静态旧日志。本次启动从未更新该文件。

这个案例采用三个信号判断当前启动：

- 日志修改时间属于本次启动；
- 运行进程实际打开本地 `winhttp.dll` 与 BepInEx Preloader；
- 新日志出现 `Chainloader initialized` 与各插件版本。

旧日志被移入备份目录，后续验证以新生成文件为准。

## 三、第一层断点：Wine 没有加载 Doorstop

Wine 的 `Mortal.exe` 已经存在 DXMT 的 `d3d11` 与 `dxgi` override，缺少 Doorstop 使用的 `winhttp` override。

在 `winecfg → Libraries` 中给 `Mortal.exe` 增加应用级设置：

```text
winhttp = native,builtin
```

应用级 override 的范围限定在游戏本体，降低对 Windows Steam 和其他程序的影响。

重启游戏后，进程能够映射本地 `winhttp.dll` 和 `BepInEx.Unity.Mono.Preloader.dll`。插件链仍停在 Chainloader 之前，说明 Doorstop 已经进入进程，下一断点位于托管入口。

## 四、第二层断点：游戏自带 corlibs 经过裁剪

只读检查得到：

```text
Mortal_Data/Managed/mscorlib.dll       3,906,048 bytes
Unity 2020.3.49 完整 mscorlib.dll      4,065,792 bytes
```

原 `doorstop_config.ini` 的搜索目录缺少完整 corlibs，Mono 最终继续使用游戏自带的裁剪版本。Preloader 会在非常早的阶段静默停止。

从合法取得、版本匹配的 Unity `2020.3.49f1` 环境准备完整 corlibs，放入：

```text
BepInEx/unstripped_corlib/
```

配置：

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

详细版 Doorstop 日志随后显示：完整 corlibs 已按顺序加载，`BepInEx.Unity.Mono.Preloader` 被调用并返回 `Done`。

corlibs 必须与 Unity 版本匹配，并遵守 Unity 的许可。本仓库和公开 Mod 包不分发这些文件。

## 五、第三层断点：BepInEx Wine 平台初始化异常

完整 corlibs 让 Preloader 继续执行，随后捕获到精确异常：

```text
System.InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

异常发生在 `PlatformUtils.SetPlatform()` 设置 `MonoMod.Utils.PlatformHelper.Current` 时。它属于 BepInEx 6 在 Wine/Proton 环境下的初始化顺序问题，与日文插件逻辑无关。

相关上游记录：

- [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)
- [BepInEx PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)

稳定版 `6.0.0-pre.2` 早于该修复。两个现有 Mod 都引用 BepInEx 6，因此本案例选择包含 PR #1254 的 x86 Mono bleeding-edge 构建 `6.0.0-be.785`。

替换前完整备份：

```text
BepInEx/core/
```

随后用 `be.785` 的完整匹配核心覆盖旧 core。入口恢复为 BepInEx 默认的 `Application::.cctor`；当目标静态构造器缺失时，BepInEx 可以创建它。实验性 `Debug::.cctor` 入口没有解决平台初始化异常。

## 六、最终验证

新启动日志：

```text
[Message: Preloader] BepInEx 6.0.0-be.785 - Mortal
[Info   :   BepInEx] System platform: Windows 10 (Wine 10.0) 64-bit
[Info   :   BepInEx] Process bitness: 32-bit (x86)
[Message:   BepInEx] Chainloader initialized
```

5 个插件进入 Chainloader：

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

日文字库报告 72,977 行文本完成注入，日志中无新的 Error/Fatal。DXMT 仍然完成 D3D11 level 11.1 初始化。

游戏内使用方法：

- 语言设置为“简体中文”；
- `F5` 控制姓名振假名；
- `F7` 切换振假名显示模式。

DiceMaster 的 `Dice Log Output` 默认通过 `Tab` 切换。本案例后续把默认显示改为关闭，并将切换键移到 `F10`；骰子控制与选项结果功能保持启用。

## 七、回滚点

至少保留三组时间戳备份：

1. 日文 Mod 合并前的 Doorstop、BepInEx 和冲突文件；
2. 完整 corlibs 与 `doorstop_config.ini` 修改前的版本；
3. `be.785` 覆盖前的完整 `BepInEx/core`。

回滚时完整退出游戏、Windows Steam 与该 wrapper 的 wineserver，整组恢复同一层文件。避免混合来自不同 BepInEx build 的核心 DLL。

## 八、案例中的通用经验

- ZIP 完整性验证应早于文件覆盖；
- 日志内容、修改时间和当前进程模块共同证明本次加载；
- Mod 加载应按 Doorstop → Preloader → Chainloader → Plugin 分层排查；
- Unity corlibs 与游戏 Unity 版本严格匹配；
- BepInEx core 按完整 build 成组替换；
- 每次只修复一个断点，并在新启动中验证。

| 结论 | 条件 | 结果 | 证据 | 置信度 |
| --- | --- | --- | --- | --- |
| 应用级 `winhttp` override 使 Doorstop 进入进程 | Wine 10、PE32 `Mortal.exe` | 本地 `winhttp.dll` 与 Preloader 被加载 | 进程模块、Doorstop 日志 | 高 |
| 完整 corlibs 修复 Preloader 早期静默停止 | Unity 2020.3.49f1 | Preloader 返回 `Done` | Doorstop 详细日志、文件大小与哈希 | 高 |
| BepInEx `be.785` 修复 Wine 平台初始化 | x86 Mono、Wine 10 | Chainloader 与 5 个插件加载 | 新 BepInEx 日志、插件输出 | 高 |
