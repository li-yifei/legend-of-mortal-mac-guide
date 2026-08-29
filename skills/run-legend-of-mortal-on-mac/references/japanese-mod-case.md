# Japanese Mod v2.4 repair case

Read this case when installing or diagnosing the Legend of Mortal Japanese Mod on the verified x86/Wine stack. Keep its conclusions bound to the versions below.

## Conditions

| Component | Case value |
| --- | --- |
| Steam AppID / Build | `1859910` / `20337760` |
| Unity | `2020.3.49f1` |
| Process | `Mortal.exe`, PE32 / x86 |
| Wine | Sikarugir Wine `10.0` |
| Mod | Japanese Mod `v2.4` |
| Initial BepInEx | `6.0.0-be.692` x86 Mono |
| Working BepInEx | `6.0.0-be.785` x86 Mono |
| Verified | 2026-08-29 |

## Observed failure

The Mod and DiceMaster files existed under the game root. A bundled 2024 `LogOutput.log` contained historical DiceMaster lines. The current launch did not update that log, and no current Chainloader evidence existed.

## Diagnostic sequence

1. The first download mixed resume mechanisms and produced an invalid ZIP central directory. A clean single-client download passed archive integrity checks.
2. Archive inspection confirmed an outer directory, x86 native components, and clean DiceMaster collisions. Replaced files were backed up before merging.
3. Wine did not load local Doorstop. A `Mortal.exe` application-level `winhttp = native,builtin` override loaded `winhttp.dll` and the preloader.
4. The game `mscorlib.dll` was `3,906,048` bytes; the matching full Unity 2020.3.49 copy was `4,065,792` bytes. Version-matched corlibs under `BepInEx/unstripped_corlib` let Doorstop invoke the preloader and return `Done`.
5. Preloader execution then exposed `Cannot set the value of PlatformHelper.Current once it has been accessed.` BepInEx issue `#1201` and PR `#1254` identify this Wine initialization problem and fix.
6. Replacing the complete backed-up BepInEx core with x86 Mono `6.0.0-be.785` resolved the platform initialization failure. The entry point returned to default `Application::.cctor`.

## Required configuration

```text
Mortal.exe DLL override: winhttp = native,builtin
```

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

Obtain corlibs legally from the exact Unity version. Never upload or redistribute them.

## Success evidence

```text
BepInEx 6.0.0-be.785
System platform: Windows 10 (Wine 10.0) 64-bit
Process bitness: 32-bit (x86)
Chainloader initialized
```

Loaded plugins:

```text
plugin by Binarizer 1.0.0
DiceMaster 1.0.0
LOM JP Font Patch 0.2.44
LOM JP Ruby Prototype 0.15.113
LOM JP String Vault 0.1.0
```

The string vault reported 72,977 injected Japanese lines. The game language was set to Simplified Chinese. `F5` controls name ruby, and `F7` changes ruby display mode.

## Rollback boundaries

Keep separate timestamped backups for:

- the game-root and BepInEx state before Mod merge;
- corlibs and Doorstop configuration;
- the complete BepInEx core before `be.785`.

Restore one complete layer at a time after the game, Windows Steam, and the exact wrapper's wineserver have exited. Do not mix core DLLs from different BepInEx builds.

## Confidence

- Doorstop override: high, based on current process modules and detail log.
- Full corlibs: high, based on version/size/hash evidence and Preloader `Done`.
- BepInEx `be.785`: high, based on a fresh Chainloader log and five plugin initialization records.
