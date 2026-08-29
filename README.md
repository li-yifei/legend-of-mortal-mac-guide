---
layout: home
title: Legend of Mortal on Apple Silicon Mac
permalink: /
---

# Legend of Mortal on Apple Silicon Mac

实机验证的《活侠传》macOS 运行、字体修复与 BepInEx Mod 排障资料库。

實機驗證的《活俠傳》macOS 執行、字型修復與 BepInEx Mod 疑難排解資料庫。

Apple Silicon Mac で『活俠傳 / Legend of Mortal』を動かし、フォントと BepInEx Mod を修復するための実機検証済みガイドです。

Apple Silicon Mac에서 《활협전 / Legend of Mortal》을 실행하고 글꼴 및 BepInEx Mod 문제를 해결하기 위한 실기 검증 가이드입니다.

## Human guides

- [简体中文](docs/guide.zhs.md)
- [繁體中文](docs/guide.zht.md)
- [日本語](docs/guide.ja.md)
- [한국어](docs/guide.ko.md)

## Case study: Japanese Mod repair

- [简体中文案例](docs/cases/japanese-mod.zhs.md)
- [日本語ケース](docs/cases/japanese-mod.ja.md)
- [한국어 사례](docs/cases/japanese-mod.ko.md)

## Agent skill

The repository includes an installable Codex/Agent Skill:

```text
skills/run-legend-of-mortal-on-mac/
```

It covers read-only inspection, Sikarugir/Wine triage, DXMT verification, Wine font repair, Doorstop/BepInEx diagnosis, and reversible changes.

## Verified stack

| Component | Verified value |
| --- | --- |
| Game | Steam AppID `1859910`, Build ID `20337760`, `release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| Executable | `Mortal.exe`, PE32 / x86 |
| Wrapper | Sikarugir Template `1.0.11` |
| Wine | Sikarugir Wine `10.0` |
| Renderer | 32-bit DXMT, D3D11 → Metal |
| Mod framework | BepInEx `6.0.0-be.785` x86 Mono |
| Last verified | 2026-08-29 |

This is a versioned field report. A Steam, game, Wine, BepInEx, or macOS update can change the outcome.

## Repository contents

```text
.
├── README.md
├── docs/
│   ├── guide.zhs.md
│   ├── guide.zht.md
│   ├── guide.ja.md
│   ├── guide.ko.md
│   └── cases/
│       ├── japanese-mod.zhs.md
│       ├── japanese-mod.ja.md
│       └── japanese-mod.ko.md
└── skills/
    └── run-legend-of-mortal-on-mac/
        ├── SKILL.md
        ├── agents/openai.yaml
        ├── references/
        └── scripts/inspect-lom-wrapper.sh
```

The repository contains documentation and read-only diagnostics. It does not include the game, Steam, Wine engines, DXMT binaries, Unity corlibs, fonts, Mod archives, save files, or account data.

## Skill installation

Copy the skill folder into your agent's skill directory. For Codex:

```bash
cp -R skills/run-legend-of-mortal-on-mac \
  "${CODEX_HOME:-$HOME/.codex}/skills/"
```

Invoke it with a request such as:

```text
Use $run-legend-of-mortal-on-mac to inspect my Sikarugir wrapper and explain why Mortal.exe fails to start.
```

The skill requires explicit user authorization before changing a live wrapper, Wine prefix, renderer modules, Steam settings, game directory, or Mod files.

## Sources

- [Legend of Mortal on Steam](https://store.steampowered.com/app/1859910/Legend_of_Mortal/)
- [Sikarugir](https://github.com/Sikarugir-App/Sikarugir)
- [DXMT](https://github.com/3Shain/dxmt)
- [BepInEx Wine fix, PR #1254](https://github.com/BepInEx/BepInEx/pull/1254)
- [LOM Japanese Mod](https://dlaqe2334.github.io/LOM-JPMOD/)

## AI 使用披露

- 问题的探索、验证与文章初稿：GPT-5.6 系列
- 文稿润色：Gemini 3.7 Flash

> 免责：发布者本人懂一些日语，不懂韩语。韩文指南经过 AI 辅助翻译与润色，建议由韩语读者进一步校对。

## License

Original documentation and scripts in this repository are released under the [MIT License](LICENSE). Third-party projects, binaries, trademarks, and game assets retain their own licenses and ownership.
