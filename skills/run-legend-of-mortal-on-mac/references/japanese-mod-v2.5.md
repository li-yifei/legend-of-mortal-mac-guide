# Japanese Mod v2.5 on game 1.06

Verified 2026-10-15, Asia/Tokyo, in an APFS clone of the user's wrapper. The production wrapper, game directory and saves were hash-checked unchanged afterwards. Source ZIP `LOM_JP_Mod_v2.5.zip`, SHA-256 `16a6de80b5896d1eba27c9e6e4654df1ba085e342cd17ccab375d86e9b1bdf35` (runtime `2.5.49`, translation `2026.10.15.354`).

## Package facts

| Item | v2.5 ships | Mac consequence |
| --- | --- | --- |
| `winhttp.dll` | Doorstop `4.3.0`, PE32+ x64 | Works under Wine with `winhttp = native,builtin` |
| `BepInEx/core` | `6.0.0-be.692` | Fails: `InvalidOperationException: Cannot set the value of PlatformHelper.Current` in `PlatformUtils.SetPlatform` |
| `doorstop_config.ini` | `dll_search_path_override = "BepInEx\core"` | Drops the `unstripped_corlib` path the Wine setup relies on |
| `BepInEx/config/BepInEx.cfg` | Minimal (console disabled) | Harmless; BepInEx fills defaults |

Extract with Finder or `ditto -x -k`. Info-ZIP `unzip` fails on the Japanese filename under `LOM_JP_FontPatch` and leaves a truncated file.

## Verified procedure

1. Exit game and Steam; back up `winhttp.dll`, `doorstop_config.ini`, the whole `BepInEx` tree and saves.
2. Copy the ZIP contents over the game root, as `README_JP.txt` instructs.
3. Replace `BepInEx/core` with the backed-up `be.785` core (whole directory; do not mix builds).
4. Set `dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"`.
5. Launch and read a `LogOutput.log` newer than the launch.

## Evidence

| Variant | Result |
| --- | --- |
| A: README overwrite only | No `LogOutput.log`; `preloader_<timestamp>.log` in game root holds the `PlatformHelper.Current` trace; all plugins inactive, game runs in Chinese |
| B: A + be.785 core + corlib path | `LegacyCleanup` projects runtime `2.5.49`; Chainloader loads 8 plugins (Binarizer, DiceMaster, FontPatch 0.2.49, RubyProto 0.15.145, Save Slot Expander 1.2.0, StringVault 92454 rows, UpdateMenu, Updater); no Error/Exception; user confirmed Japanese text in game |

The updater reached GitHub through Wine; the stable manifest was a `0.0.0` placeholder, result `No applicable update`. Whether a real update rewrites `BepInEx/core` or `doorstop_config.ini` is unverified: after any in-game update, re-check the core version (`strings BepInEx.Core.dll | grep 6.0.0-be`) and the ini path.

## Triage

- `preloader_*.log` with `PlatformHelper.Current` → core is be.692; restore be.785.
- No new `LogOutput.log` → check the `winhttp` override and that `winhttp.dll` is PE32+.
- Preloader stops early → missing or mismatched `unstripped_corlib`.

Upgrading over an existing v2.4 install was not tested; v2.5's `LOM_JP_LegacyCleanup` is designed to sweep v2.4 leftovers.
