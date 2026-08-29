---
layout: page
title: 案例：Wine 10 / x86 版《活侠传》加载日文 Mod
permalink: /docs/cases/japanese-mod.zhs/
---

[返回简体中文指南](../guide.zhs.md) · [繁體中文](../guide.zht.md) · [日本語](japanese-mod.ja.md) · [한국어](japanese-mod.ko.md)

## 结论

在 macOS 环境下通过 Wine 10.0 运行 32 位（x86）《活侠传》时，日文 Mod v2.4 与 DiceMaster 模组解压后默认无法加载，根本原因在于 **Wine DLL 拦截未生效**、**游戏自带 corlibs 裁剪导致 Preloader 静默中断** 以及 **BepInEx 6 旧版本在 Wine 环境下的平台初始化异常** 三重阻碍。

通过配置应用程序级 `winhttp` override、引入匹配 Unity `2020.3.49f1` 的完整未裁剪 corlibs、配置 Doorstop 搜索路径并升级至修复版 BepInEx `6.0.0-be.785`（x86 Mono），即可彻底修复加载链，使 Chainloader 成功加载全部 5 个插件并注入 72,977 行日文文本。

原本在此环境下失效的 **DiceMaster 模组**，由于底层依赖完全相同的 BepInEx 运行时环境，**通过本案例的同一套 Doorstop / corlibs / BepInEx Wine 修复路径可同样恢复正常加载与运行**。

## 适用条件

| 项目 | 适用 / 验证条件 |
| --- | --- |
| 游戏版本 | Steam AppID `1859910`，Build ID `20337760`（`release_1.0.5000.13`） |
| Unity 引擎 | `2020.3.49f1` |
| 进程架构 | `Mortal.exe`，PE32 / x86（32 位） |
| 运行环境 | Sikarugir Wine `10.0`（64 位 Prefix / 32 位 DXMT） |
| 目标 Mod | [日文 Mod v2.4](https://dlaqe2334.github.io/LOM-JPMOD/)、DiceMaster 1.0.0 |
| BepInEx 版本 | 初始 `6.0.0-be.692` → 修复验证版本 `6.0.0-be.785` x86 Mono |
| 验证日期 | 2026-08-29 |

## 最短修复路径

1. **配置 DLL Override**：在 `winecfg` 的函数库（Libraries）中，为 `Mortal.exe` 添加应用程序专属配置 `winhttp = native,builtin`。
2. **部署完整 corlibs**：将 Unity `2020.3.49f1` 的完整未裁剪 corlibs 放入 `BepInEx/unstripped_corlib/`，并在 `doorstop_config.ini` 中配置 `dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"`。
3. **升级 BepInEx 核心**：将 `BepInEx/core` 整体替换为包含 Wine 修复补丁（PR #1254）的 x86 Mono 构建版本 `6.0.0-be.785`，入口点保持默认 `Application::.cctor`。
4. **设置游戏内语言**：启动游戏并将游戏内语言切换为“简体中文”。

## 成功判断标准

- [x] **日志就绪**：`BepInEx/LogOutput.log` 包含 `BepInEx 6.0.0-be.785`、`Process bitness: 32-bit (x86)` 与 `Chainloader initialized`。
- [x] **插件全加载**：5 个插件全部加载成功（`plugin by Binarizer 1.0.0`、`DiceMaster 1.0.0`、`LOM JP Font Patch 0.2.44`、`LOM JP Ruby Prototype 0.15.113`、`LOM JP String Vault 0.1.0`）。
- [x] **文本与热键生效**：游戏界面成功注入 72,977 行日文文本，无 Error/Fatal 报错；游戏中按 `F5` 可切换姓名振假名，按 `F7` 可切换显示模式。
- [x] **DiceMaster 正常工作**：DiceMaster 控制台及功能在游戏中可正常呼出使用。

---

## 1. 问题现象与根因

### 问题现象

将日文 Mod v2.4 或 DiceMaster 压缩包解压至《活侠传》游戏目录后，启动游戏出现以下故障：
- 游戏正常启动，但 Mod 均未生效，游戏语言仍为中文且无任何 Mod 界面；
- `BepInEx/LogOutput.log` 未生成、未更新，或日志在 Preloader 阶段静默中断；
- 若启用了控制台或调试输出，进程在初始化阶段抛出 `PlatformHelper.Current` 异常崩溃。

### 根因分析

Mod 无法加载由以下三层技术阻碍串联导致：
1. **Doorstop 注入失效**：Wine 默认使用内置（builtin）的 `winhttp.dll`，忽略游戏目录下的原生（native）Doorstop 代理 DLL，导致 Preloader 完全未被拉起。
2. **corlibs 被裁剪（Stripped）**：游戏随附的 `mscorlib.dll`（约 3.90 MB）经过裁剪，缺少 BepInEx Preloader 反射与程序集加载所需的元数据与类型定义，导致 Preloader 初始化静默中止。
3. **BepInEx 6 平台初始化缺陷**：旧版 BepInEx（如 `6.0.0-be.692`）在 Wine 32 位环境下尝试识别平台架构时逻辑冲突，抛出只读属性重复赋值异常。

<details>
<summary>技术细节：异常堆栈与调用链分析</summary>

```text
InvalidOperationException:
Cannot set the value of PlatformHelper.Current once it has been accessed.
  at BepInEx.PlatformHelper.set_Current (BepInEx.PlatformHelper+Platform value)
  at BepInEx.Unity.Mono.Preloader.Preloader.Run ()
```

- **问题追踪**：记录于 [BepInEx issue #1201](https://github.com/BepInEx/BepInEx/issues/1201)，并在 [PR #1254](https://github.com/BepInEx/BepInEx/pull/1254) 中修复。
- **Doorstop 原理**：Windows 版 Unity 进程在启动时动态加载 `winhttp.dll`，Doorstop 通过同名 DLL 劫持在 Unity Mono 运行时初始化前注入 Preloader，随后由 Preloader 调用 Chainloader 加载各插件 DLL。

</details>

---

## 2. 排障检查与诊断

在执行修复前，按以下清单逐项排查当前环境状态：

1. **检查进程架构**：确认 `Mortal.exe` 为 32 位（PE32 / x86）可执行文件。
2. **检查 DLL Override**：检查 Wine prefix 注册表中是否已针对 `Mortal.exe` 设置 `winhttp` override。
3. **检查 corlibs 完整性**：对比游戏目录下的 `mscorlib.dll` 与未裁剪版本的文件大小。
4. **检查 BepInEx Core 版本**：确认 `BepInEx/core` 中的组件构建版本，确认是否包含 Wine 初始化补丁。
5. **检查 Mod 压缩包安全性**：解压前确认压缩包内无绝对路径或 `..` 路径穿越结构，并验证原生 DLL 均为 x86 架构。

<details>
<summary>技术细节：安全性排查与文件比对清单</summary>

- **文件大小对照**：
  ```text
  游戏自带 mscorlib.dll       3,906,048 bytes (裁剪版 / Stripped)
  Unity 2020.3.49 完整版       4,065,792 bytes (未裁剪版 / Unstripped)
  ```
- **安全边界说明**：corlibs 必须严格匹配 Unity 引擎版本（`2020.3.49f1`），并在遵守 Unity 软件许可协议的前提下通过合法渠道获取。公开仓库与 Mod 分发包应遵循零字体、零 corlibs 分发原则。
- **哈希与备份检查**：在覆盖前应对原有的 DiceMaster DLL 及配置文件执行 SHA-256 校验并备份，防止合并解压造成配置丢失。

</details>

---

## 3. 分步修复操作

### 步骤 1：配置应用程序专属 DLL Override

打开对应 Wine prefix 的配置工具 `winecfg`：
1. 切换至 **函数库（Libraries）** 标签页；
2. 在 **应用程序（Applications）** 列表中添加 `Mortal.exe` 并选中；
3. 在 **新增函数库顶替（New override for library）** 中输入 `winhttp` 并点击添加；
4. 确认其加载顺序设置为：
   ```text
   winhttp = native,builtin
   ```

### 步骤 2：部署 Unity 2020.3.49f1 完整 corlibs 并配置 Doorstop

1. 在游戏根目录下的 `BepInEx` 文件夹中创建 `unstripped_corlib` 目录：
   ```text
   BepInEx/unstripped_corlib/
   ```
2. 将版本完全匹配的 Unity `2020.3.49f1` 完整未裁剪 corlibs 放入该目录。
3. 在游戏根目录下创建或编辑 `doorstop_config.ini`，确保内容如下：
   ```ini
   [General]
   enabled = true
   target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

   [UnityMono]
   dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
   ```

### 步骤 3：升级 BepInEx 核心至修复版本（6.0.0-be.785）

1. 完整备份现有的 `BepInEx/core` 目录。
2. 将 `BepInEx/core` 整体替换为包含 PR #1254 修复的 x86 Mono 构建版本 **`6.0.0-be.785`**。
3. 托管入口点保持默认配置（`Application::.cctor`），无需指定非常规入口。

### 步骤 4：设置游戏内语言

1. 启动游戏并进入主菜单设置。
2. 将游戏语言选择为 **“简体中文”**（日文 Mod 补丁挂载于简体中文文本管线上）。

<details>
<summary>技术细节：Doorstop 配置项与 Mono 程序集加载原理</summary>

- `dll_search_path_override` 参数指示 Mono 运行时在解析核心程序集时优先搜索 `BepInEx\unstripped_corlib`，从而覆盖 `Mortal_Data\Managed` 中的裁剪版程序集。
- 默认入口点 `Application::.cctor` 在 Unity 引擎的 `UnityEngine.Application` 类静态构造函数执行时触发 Preloader，具有最高的跨版本兼容性与稳定性。

</details>

---

## 4. 验证与运行测试

### 1. 日志加载验证

启动游戏后查看 `BepInEx/LogOutput.log`，确认包含以下输出：

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

### 2. 插件加载列表验证

确认 Chainloader 依次成功加载全部 5 个插件且无 Error/Fatal 报错：

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

### 3. 游戏内功能与热键验证

- **文本注入**：进入游戏，界面文本已正常替换为日文，成功注入 72,977 行文本。
- **热键控制**：
  - 按 **`F5`**：切换人名振假名（ルビ）显示。
  - 按 **`F7`**：切换显示模式。

### 4. DiceMaster 与多 Mod 共存说明

**DiceMaster 模组** 与日文 Mod 共享同一 BepInEx 6 运行时。在 Wine 环境下，DiceMaster 单独运行时遭遇的故障原因（`winhttp` 未代理、corlibs 裁剪导致 Preloader 中断、BepInEx Wine 平台崩溃）与日文 Mod 完全相同。因此，**通过本修复路径配置后，DiceMaster 即可与日文 Mod 完美共存并恢复所有功能**。

<details>
<summary>技术细节：完整验证日志输出</summary>

```text
[Message:   BepInEx] BepInEx 6.0.0-be.785 - Mortal
[Info   :   BepInEx] System platform: Windows 10 (Wine 10.0) 64-bit
[Info   :   BepInEx] Process bitness: 32-bit (x86)
[Message:   BepInEx] Preloader started
[Info   :   BepInEx] Loaded 1 patcher method from [BepInEx.Preloader 6.0.0.785]
[Info   :   BepInEx] 1 patcher result: 1 patch applied
[Message:   BepInEx] Preloader finished
[Message:   BepInEx] Chainloader ready
[Message:   BepInEx] Chainloader initialized
[Info   :   BepInEx] Loading [plugin by Binarizer 1.0.0]
[Info   :   BepInEx] Loading [DiceMaster 1.0.0]
[Info   :   BepInEx] Loading [LOM JP Font Patch 0.2.44]
[Info   :   BepInEx] Loading [LOM JP Ruby Prototype 0.15.113]
[Info   :   BepInEx] Loading [LOM JP String Vault 0.1.0]
```

</details>

---

## 5. 回滚方案与安全边界

### 三级回滚边界

若修复过程中需要还原环境，请根据故障节点选择对应回滚阶段：

1. **阶段 1：恢复至 Mod 安装前**
   - 删除游戏目录下的 `BepInEx`、`doorstop_config.ini`、`winhttp.dll` 及 Mod 资源文件；
   - 恢复安装前备份的原版游戏文件。
2. **阶段 2：恢复至 corlibs 配置前**
   - 删除 `BepInEx/unstripped_corlib` 目录；
   - 将 `doorstop_config.ini` 中的 `dll_search_path_override` 还原为空或默认值。
3. **阶段 3：恢复至 BepInEx Core 升级前**
   - 删除 `BepInEx/core` 目录；
   - 还原原有的 `BepInEx/core` 备份（如 `be.692`）。

### 安全操作规范

- **进程退出**：在执行任何文件备份、替换或回滚前，必须彻底退出游戏、Windows 版 Steam 以及当前 prefix 的 wineserver 进程（`wineserver -k`）。
- **原子替换**：替换或恢复 `BepInEx/core` 时必须整目录成套操作，切勿混用来自不同 BepInEx 构建版本的 DLL 文件。
- **凭证隔离**：Mod 安装与排障全程不触及 Steam 账号令牌与登录凭证。

<details>
<summary>技术细节：Wineserver 进程清理与安全防护边界</summary>

- **结束 Wine 服务会话**：
  ```bash
  wineserver -k
  ```
- **验证进程清理状态**：确保无挂起的 `Mortal.exe`、`Steam.exe` 或 `wineserver` 僵尸进程占用文件句柄后再执行文件覆盖或还原。
</details>
