---
layout: home
title: 活侠传 macOS 指南 2026
permalink: /
---

在 Mac 上也能玩《活侠传》，还能安装 Mod。这是一份基于 Apple Silicon 实机验证的配置指南与排障记录，介绍如何在 macOS 上通过 Wine 运行自购正版《活侠传》，并安装与修复 BepInEx 模组。

## TL;DR

手动配置涉及 32 位 DXMT 替换、注册表配置、Unity corlibs 与 BepInEx 补丁等底层操作。**建议普通用户直接将本指南提供给 AI 编码助手代劳排障与命令执行。**

操作时请保留必要的人工安全边界：
- **手动登录**：在独立界面自行登录 Steam，绝不向 AI 提供账号密码或令牌；
- **人工确认**：关键文件替换与高危终端命令需人工核对后再执行；
- **事前备份**：修改 Engine、Wine prefix 或游戏目录前务必创建带时间戳的副本，确保随时可回滚。

## 多语言指南

- [简体中文指南](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.zhs/)
- [繁體中文指南](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.zht/)
- [日本語ガイド](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.ja/)
- [한국어 가이드](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.ko.html)

## Mod 案例

同一套 Doorstop、Unity corlibs 与 BepInEx Wine 修复路径，已验证适用于日文 Mod 与 DiceMaster 模组。

- [简体中文案例](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/cases/japanese-mod.zhs/)
- [日本語ケース](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/cases/japanese-mod.ja/)
- [한국어 사례](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/cases/japanese-mod.ko.html)

## 已验证配置

| 项目 | 已验证配置 |
| --- | --- |
| 游戏 | Steam AppID `1859910`，Build `20337760`，`release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 游戏程序 | `Mortal.exe`，PE32 / x86 |
| 包装器 | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| 图形后端 | 32 位 DXMT，D3D11 → Metal |
| Mod 框架 | BepInEx `6.0.0-be.785` x86 Mono |

## AI 使用披露

- 问题探索、验证与文章初稿：GPT-5.6 系列
- 文稿润色：Gemini 3.7 Flash

> 免责声明：发布者懂一些日语，不懂韩语。韩文指南经过 AI 辅助翻译与润色，建议由韩语读者进一步校对。

---

[项目源码与完整文档](https://github.com/li-yifei/legend-of-mortal-mac-guide) · [MIT License](https://li-yifei.github.io/legend-of-mortal-mac-guide/LICENSE)
