# Game 1.06: x64 Doorstop repair

Verified 2026-10-15, Asia/Tokyo. Source: the local runtime upgrade report, fresh process/module and startup-log inspection, and the user's subsequent in-game confirmations. Keep private paths, account IDs and saves outside public artifacts.

## Conditions and final state

| Component | Verified value |
| --- | --- |
| Steam AppID / Build | `1859910` / `25953419` (game 1.06) |
| Executables | `Mortal.exe` and `UnityPlayer.dll`, PE32+ / x86-64 |
| Unity | `2020.3.49f1` |
| Doorstop | Official `4.4.0`, Windows x64 `winhttp.dll` |
| BepInEx | Retained managed core `6.0.0-be.785` |
| Plugins | Retained DiceMaster `1.0.0`, LOM Save Slot Expander `1.2.0` |
| Creator / Template runtime | `1.0.2` / `1.0.22` |
| Wine | Sikarugir `10.0 revision 8` |
| DXMT | Template-packaged `v0.80-244-g7c8dee1`, matching Windows and Unix components |

## Diagnosis and scoped repair

The Steam update changed the game from x86 to x64. Its existing native Doorstop `winhttp.dll` remained x86; the current process loaded Wine's builtin x64 `winhttp.dll` instead. A log timestamped 16:12 was mistakenly used to assess the 16:14 launch. Require a new log tied to the current process.

After the user exited the game and authorized the repair, a complete wrapper backup and per-component hashes were retained. Doorstop's native DLL was replaced with official Windows x64 `4.4.0`. The existing managed BepInEx core, DiceMaster and Save Slot Expander lacked the `Requires32Bit` flag and successfully loaded when retained. Inspect CLR flags, native dependencies and actual in-game behavior before generalizing this to other plugin binaries.

Preserve the game's application-level `winhttp = native,builtin` override, its existing Doorstop configuration and exact-version corlibs when they are verified. Unity stayed at `2020.3.49f1` in this update. Runtime upgrades were performed in the same maintenance session; record those separately from the native architecture mismatch that explained the failed injection.

## Evidence and confidence

The 16:25 run logged:

```text
Process bitness: 64-bit (x64)
Chainloader initialized
Loading [DiceMaster 1.0.0]
Loading [LOM Save Slot Expander 1.2.0]
Chainloader startup complete
```

Current module inspection showed game-local x64 `winhttp.dll`, BepInEx Unity Mono, and the upgraded `winemetal.so`. Player.log showed D3D11 level 11.1, Apple GPU, audio initialization and scene load. No new Error/Fatal/Exception appeared in this startup. Confidence in injection and startup: high for this build and setup.

The user confirmed the save extension working. A subsequent user-provided screenshot showed DiceMaster's option-benefit information. Confidence in the extension's reported working state and the visible hint display: high. Hint accuracy, new-story script parsing, dice control and special settlements remain unverified: compare before/after gameplay values and actual branches in controlled events. The current menu binding is `F10` (`Fn + F10` on the internal keyboard where applicable); menu interaction itself remains unverified. Do not reproduce the screenshot's story text in public documentation.

Steam WebView IME composition, post-upgrade font appearance, window focus, sleep/wake, and long-session behavior require separate validation. Historical focus and font cases remain useful symptom-based references, not new-build acceptance evidence.

## Japanese Mod v2.5 package boundary

Static inspection found an x64 Doorstop `4.3.0` entry and bundled BepInEx `be.692`; a whole-package overlay replaces the working `be.785` core. The isolated runtime test, verified procedure and triage are in [japanese-mod-v2.5.md](japanese-mod-v2.5.md).

## Wine 11 observation

Sikarugir Wine `11.0 revision 1` stalled at `wineboot` in the existing prefix and separate empty prefixes on this machine. Its root cause is unresolved. Sikarugir `10.0 revision 8` initialized a fresh test prefix and passed Steam login plus the actual game/plugin startup. Keep the result machine-specific; it does not establish universal Wine 11 incompatibility.

## Rollback

After an authorized normal exit of the game, Windows Steam and only the target wrapper's Wine session, restore the affected layer from its timestamped backup. Full-wrapper restoration also restores prefix/save state: account for gameplay since backup before rollback. Keep the BepInEx core build internally consistent. Preserve custom launch targets and verified renderer search paths during template upgrades.

## Official sources

- [Doorstop 4.4.0](https://github.com/NeighTools/UnityDoorstop/releases/tag/v4.4.0)
- [Creator 1.0.2](https://github.com/Sikarugir-App/Creator/releases/tag/v1.0.2)
- [Template assets](https://github.com/Sikarugir-App/Template/releases/tag/v1.0)
- [Engine assets](https://github.com/Sikarugir-App/Engines/releases/tag/v1.0)
