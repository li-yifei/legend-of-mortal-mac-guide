---
layout: home
title: 《活侠传》Apple Silicon Mac 运行指南
permalink: /
---

# 《活侠传》Apple Silicon Mac 运行指南

实机验证的 macOS 运行、字体修复与 BepInEx Mod 排障记录。

## 语言

- [简体中文指南](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.zhs/)
- [繁體中文指南](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.zht/)
- [日本語ガイド](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.ja/)
- [한국어 가이드](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/guide.ko.html)

## 日文 Mod 案例

同一套 Doorstop、Unity corlibs 与 BepInEx Wine 修复路径，也适用于 DiceMaster 模组。

- [简体中文案例](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/cases/japanese-mod.zhs/)
- [日本語ケース](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/cases/japanese-mod.ja/)
- [한국어 사례](https://li-yifei.github.io/legend-of-mortal-mac-guide/docs/cases/japanese-mod.ko.html)

## 已验证配置

| 项目 | 版本或结果 |
| --- | --- |
| 游戏 | Steam AppID `1859910`，Build `20337760`，`release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| 游戏程序 | `Mortal.exe`，PE32 / x86 |
| 包装器 | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| 图形后端 | 32 位 DXMT，D3D11 → Metal |
| Mod 框架 | BepInEx `6.0.0-be.785` x86 Mono |

## 内容范围

- Sikarugir 与 Wine 安装
- 32 位 DXMT 图形后端排障
- Wine 字体修复
- Doorstop 与 BepInEx Mod 加载
- 只读诊断脚本与可回滚操作

版本、游戏、Wine、BepInEx 或 macOS 更新都可能改变结果。完整步骤与验证记录请从上方语言指南进入。

## AI 使用披露

- 问题探索、验证与文章初稿：GPT-5.6 系列
- 文稿润色：Gemini 3.7 Flash

> 免责：发布者本人懂一些日语，不懂韩语。韩文指南经过 AI 辅助翻译与润色，建议由韩语读者进一步校对。

---

[项目源码与完整文档](https://github.com/li-yifei/legend-of-mortal-mac-guide) · [MIT License](https://li-yifei.github.io/legend-of-mortal-mac-guide/LICENSE)
