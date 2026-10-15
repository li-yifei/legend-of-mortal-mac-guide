---
layout: home
title: 活侠传 macOS 指南 2026
permalink: /
---

这份指南记录了在 Apple Silicon Mac 上运行正版《活侠传》的方法，以及字体缺失、Mod 失效和切换窗口后失去控制等问题的处理步骤。按自己遇到的症状阅读对应章节即可。

## 从这里开始

| 你现在的情况 | 建议阅读 |
| --- | --- |
| 更新到 1.06 后，原本可用的 Mod 同时失效 | [1.06 升级案例](docs/cases/game-1.06.zhs.md)：先检查游戏和 Mod 入口 DLL 的位数 |
| 首次在 Mac 上安装游戏 | [简体中文指南](docs/guide.zhs.md)：准备包装器和 Windows 版 Steam |
| 游戏闪退、商店数字空白，或切换窗口后无法操作 | 各语言指南中的症状速查和已知问题 |
| 想了解旧版日文 Mod 如何加载 | [2026 年 8 月实测案例](docs/cases/japanese-mod.zhs.md) |

**版本说明：** 1.06 案例记录的是 2026 年 10 月 15 日、Build `25953419` 的 64 位游戏。主指南中的 32 位图形和 Mod 配置属于 2026 年 8 月的 Build `20337760`；具体组件选择以自己安装的游戏版本为准。

1.06 已确认 x64 Doorstop 恢复 Mod 框架加载，存档扩展可用，DiceMaster 的收益提示可以显示。新剧情数值准确性、骰点控制与 F10 菜单等功能仍待验证。日文 Mod v2.5 已完成包内静态分析，macOS 实际运行仍待测试验证。

## 让 AI 助手协助操作

缺少 Wine 或终端经验的读者，可以把对应指南交给 AI 编码助手，先检查本机环境，再按症状处理。操作时保留以下边界：

- **手动登录**：在独立界面自行登录 Steam，绝不向 AI 提供账号密码或令牌；
- **人工确认**：关键文件替换与高危终端命令需人工核对后再执行；
- **事前备份**：修改 Engine、Wine prefix 或游戏目录前务必创建带时间戳的副本，确保随时可回滚。

## 多语言指南

- [简体中文指南](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.zhs/)
- [繁體中文指南](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.zht/)
- [日本語ガイド](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.ja/)
- [한국어 가이드](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.ko.html)

## Mod 案例

### 1.06：更新后 Mod 失效

- [简体中文](docs/cases/game-1.06.zhs.md)
- [繁體中文](docs/cases/game-1.06.zht.md)
- [日本語](docs/cases/game-1.06.ja.md)
- [한국어](docs/cases/game-1.06.ko.md)

### 旧版：日文 Mod v2.4 与 DiceMaster

以下案例记录 2026 年 8 月、Build `20337760` 的 32 位配置。

- [简体中文案例](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/cases/japanese-mod.zhs/)
- [日本語ケース](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/cases/japanese-mod.ja/)
- [한국어 사례](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/cases/japanese-mod.ko.html)

## 1.06 本机验证配置

| 项目 | 已验证配置 |
| --- | --- |
| 游戏 | Steam AppID `1859910`，Build `25953419`，1.06 |
| Unity | `2020.3.49f1` |
| 游戏程序 | `Mortal.exe`，PE32+ / x64 |
| 包装器运行组件 | Sikarugir Template `1.0.22` |
| Wine | Sikarugir Wine `10.0 revision 8` |
| 图形后端 | 模板配套 DXMT `v0.80-244-g7c8dee1`，D3D11 → Metal |
| Mod 入口 / 框架 | Doorstop `4.4.0` Windows x64 / 保留 BepInEx `6.0.0-be.785` 托管核心 |
| 验证日期 | 2026-10-15 |

## AI 使用披露

- 问题探索、验证与文章初稿：GPT-5.6 系列
- 文稿润色：Gemini 3.7 Flash
- 2026 年 10 月文章改写与语言润色：Codex + Gemini 3.8 Flash

> 免责声明：发布者懂一些日语，不懂韩语。韩文指南经过 AI 辅助翻译与润色，建议由韩语读者进一步校对。

---

[项目源码与完整文档](https://github.com/li-yifei/legend-of-mortal-mac-guide) · [MIT License](https://li-yifei.github.io/legend-of-mortal-mac-guide/LICENSE)
