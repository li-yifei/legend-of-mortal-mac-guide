---
layout: home
title: "活侠传 macOS 指南 2026"
permalink: /
---

在 Apple Silicon Mac 上运行正版《活侠传》，并处理字体缺失、Mod 失效、切换窗口后无法操作等问题。所有步骤均经本机实测，验证范围逐项注明。

> **你的游戏是哪个版本？** 在终端运行 `file ".../LegendOfMortal/Mortal.exe"`：
> - 显示 `PE32+ … x86-64` → **1.06（64 位）**，阅读下方语言指南即可；
> - 从 1.05 升级后 Mod 全部失效 → 只需换一个 DLL，见指南中的 **「从 1.05 升级到 1.06」**；
> - 显示 `PE32 … Intel 80386` → 1.05（32 位），见指南文末的历史配置。
> - **日本語化 Mod v2.5 を使う方**：README どおり入れたあと、Mac では 2 か所の修正が必要です → [手順はこちら](docs/cases/japanese-mod-v2.5.ja.md)
{: .callout}

## 语言指南 / Guides

| 语言 | 主指南（1.06） | 1.06 升级案例 | 日文 Mod |
| --- | --- | --- | --- |
| 简体中文 | [指南](docs/guide.zhs.md) | [案例](docs/cases/game-1.06.zhs.md) | [v2.4 旧版案例](docs/cases/japanese-mod.zhs.md) |
| 繁體中文 | [指南](docs/guide.zht.md) | [案例](docs/cases/game-1.06.zht.md) | — |
| 日本語 | [ガイド](docs/guide.ja.md) | [事例](docs/cases/game-1.06.ja.md) | **[v2.5 を Mac で導入](docs/cases/japanese-mod-v2.5.ja.md)** · [v2.4 旧版](docs/cases/japanese-mod.ja.md) |
| 한국어 | [가이드](docs/guide.ko.md) | [사례](docs/cases/game-1.06.ko.md) | [v2.4 이전 사례](docs/cases/japanese-mod.ko.md) |

## 1.06 已验证配置

| 项目 | 已验证配置 |
| --- | --- |
| 游戏 | Steam AppID `1859910`，Build `25953419`，1.06，`Mortal.exe` PE32+ / x64 |
| Unity | `2020.3.49f1` |
| 包装器 | Sikarugir Template `1.0.22`，Wine `10.0 revision 8` |
| 图形后端 | DXMT `v0.80-244-g7c8dee1`，D3D11 → Metal |
| Mod | Doorstop `4.4.0` x64 + BepInEx `6.0.0-be.785` |
| 验证日期 | 2026-10-15 |

已确认：Mod 框架加载、存档扩展可用、DiceMaster 收益提示显示。待验证项见各语言的 1.06 升级案例。

## 让 AI 助手协助

可以把指南交给 AI 编码助手，让它先只读检查本机环境再按症状处理。请自己手动登录 Steam，不要向 AI 提供账号密码或令牌；文件替换和高风险命令先人工确认；修改 Engine、Wine prefix 或游戏目录前先做带时间戳的备份。

## AI 使用披露

- 问题探索、验证与文章初稿：GPT-5.6 系列
- 文稿润色：Gemini 3.7 Flash
- 2026 年 10 月改写：Codex、Gemini 3.8 Flash、Claude

> 发布者懂一些日语，不懂韩语。韩文指南为 AI 辅助翻译，欢迎韩语读者校对。

---

[项目源码与完整文档](https://github.com/li-yifei/legend-of-mortal-mac-guide) · [MIT License](https://github.com/li-yifei/legend-of-mortal-mac-guide/blob/main/LICENSE)
