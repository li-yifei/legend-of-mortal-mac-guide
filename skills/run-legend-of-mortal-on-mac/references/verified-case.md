# Verified Legend of Mortal case

Use this reference to compare a target environment with the field-tested stack. Treat every value as version-bound.

## Version routing

The table below is the historical 2026-08-29 x86 baseline. For 1.06 / Build `25953419`, use [game-1.06-upgrade.md](game-1.06-upgrade.md): the game is x64, Doorstop `4.4.0` x64 restored injection, and the existing managed BepInEx `be.785` core was retained. Japanese Mod compatibility with that build remains unverified.

## Historical known-good stack

| Component | Verified value |
| --- | --- |
| Steam AppID | `1859910` |
| Steam Build ID | `20337760` |
| Game release | `release_1.0.5000.13` |
| Unity | `2020.3.49f1` |
| Executable | `Mortal.exe`, PE32 / x86 |
| Wrapper | Sikarugir Template `1.0.11` |
| Engine | Sikarugir Wine `10.0` |
| Renderer | matching 32-bit DXMT D3D11 modules |
| BepInEx | `6.0.0-be.785` x86 Mono |
| Verification date | 2026-08-29 |

## Renderer evidence

```text
Loaded C:\windows\system32\winemetal.dll
Loaded C:\windows\system32\DXGI.DLL
Loaded C:\windows\system32\d3d11.dll
```

```text
Direct3D:
    Version:  Direct3D 11.0 [level 11.1]
    Renderer: Apple M5 Pro
Begin MonoManager ReloadAssembly
```

## Font evidence

- Initial prefix: 2 physical font files, `sourcehansans.ttc` and `unifont.ttf`.
- `cjkfonts` was already present.
- After Winetricks `allfonts`: 121 files, approximately 284 MB.
- Arial, Tahoma, Calibri, Meiryo, and WenQuanYi mappings were present.
- User verified that shop price and total text returned.

## Mod evidence

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

Five plugins loaded in the tested setup, including DiceMaster and the Japanese localization plugins. The Japanese string vault reported 72,977 injected lines.

## Confidence

- Renderer: high, based on module loads, hashes, and Unity log.
- Font repair: high, based on files, registry mappings, and in-game confirmation.
- Mod repair: high, based on Doorstop detail logs, a fresh BepInEx log, and plugin initialization output.
