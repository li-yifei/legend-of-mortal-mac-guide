# Legend of Mortal on Apple Silicon Mac

实机验证的《活侠传》macOS 运行、字体修复与 BepInEx Mod 排障资料库。

實機驗證的《活俠傳》macOS 執行、字型修復與 BepInEx Mod 疑難排解資料庫。

Apple Silicon Mac で『活俠傳 / Legend of Mortal』を動かし、フォントと BepInEx Mod を修復するための実機検証済みガイドです。

Apple Silicon Mac에서 《활협전 / Legend of Mortal》을 실행하고 글꼴 및 BepInEx Mod 문제를 해결하기 위한 실기 검증 가이드입니다.

> 版本入口：四语主指南已按游戏 1.06（Build `25953419`，64 位）改写；1.05（Build `20337760`，32 位）配置收在各指南文末。

## 从这里开始 / Start here

1. **从 1.05 升级后 Mod 全部失效**：读指南的「从 1.05 升级到 1.06」——只需把 `winhttp.dll` 换成 x64 版 Doorstop；
2. **使用日文 Mod v2.5 / 日本語化 Mod v2.5 を使う方**：按 README 全部覆盖后，Mac 上还要把 `BepInEx/core` 换回 be.785，并在 `doorstop_config.ini` 加入 `BepInEx\unstripped_corlib`。手順：[日本語化 Mod v2.5 を Mac で導入する](docs/cases/japanese-mod-v2.5.ja.md)；
3. **首次安装**：读指南第 1 节；
4. **启动报错 / 商店数字空白 / 切窗口后无响应**：按指南的症状速查表找对应章节。

## Human guides / 语言指南

- [简体中文指南](docs/guide.zhs.md)
- [繁體中文指南](docs/guide.zht.md)
- [日本語ガイド](docs/guide.ja.md)
- [한국어 가이드](docs/guide.ko.md)

## 1.06 升级案例 / Game 1.06 update

- [简体中文](docs/cases/game-1.06.zhs.md)
- [繁體中文](docs/cases/game-1.06.zht.md)
- [日本語](docs/cases/game-1.06.ja.md)
- [한국어](docs/cases/game-1.06.ko.md)

## 日文 Mod v2.5（1.06）/ Japanese Mod v2.5

- [日本語：日本語化 Mod v2.5 を Mac で導入する](docs/cases/japanese-mod-v2.5.ja.md)

## 旧版日文 Mod 案例 / Historical Japanese Mod case

- [简体中文案例](docs/cases/japanese-mod.zhs.md)
- [日本語ケース](docs/cases/japanese-mod.ja.md)
- [한국어 사례](docs/cases/japanese-mod.ko.md)

## Agent skill

The repository includes an installable Codex/Agent Skill:

```text
skills/run-legend-of-mortal-on-mac/
```

It covers read-only inspection, Sikarugir/Wine triage, DXMT verification, Wine font repair, Doorstop/BepInEx diagnosis, and reversible changes.

## 1.06 verified startup stack

| Component | Verified value (2026-10-15) |
| --- | --- |
| Game | AppID `1859910`, Build `25953419`, 1.06, PE32+ / x64 |
| Unity | `2020.3.49f1` |
| Doorstop | `4.4.0` Windows x64 |
| BepInEx | Retained managed core `6.0.0-be.785` |
| Creator / Template runtime | `1.0.2` / `1.0.22` |
| Wine | Sikarugir `10.0 revision 8` |
| DXMT | Template-packaged `v0.80-244-g7c8dee1` |

Plugin feature coverage and machine-specific limits are recorded in the 1.06 cases. Japanese Mod v2.5 was verified on 2026-10-15 in an isolated wrapper clone: its bundled x64 Doorstop `4.3.0` works, but its bundled BepInEx `be.692` fails under Wine with `PlatformHelper.Current`. Restoring the `be.785` core and the `unstripped_corlib` search path loads all 8 plugins without errors.

## Historical verified stack

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
│       ├── game-1.06.{zhs,zht,ja,ko}.md
│       ├── japanese-mod-v2.5.ja.md
│       └── japanese-mod.{zhs,ja,ko}.md
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
- 2026-10 可读性与语言编辑（不包含新版本技术验证）：Codex + Gemini 3.8 Flash

> 免责：发布者本人懂一些日语，不懂韩语。韩文指南经过 AI 辅助翻译与润色，建议由韩语读者进一步校对。

## License

Original documentation and scripts in this repository are released under the [MIT License](LICENSE). Third-party projects, binaries, trademarks, and game assets retain their own licenses and ownership.
