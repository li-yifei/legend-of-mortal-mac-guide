# Doorstop and BepInEx workflow

Trace the first missing stage: Doorstop → Preloader → Chainloader → Plugin.

Inspect current `Mortal.exe`, `UnityPlayer.dll`, and native `winhttp.dll` architectures before changing the chain. The x86 case below belongs to Build `20337760`. For 1.06 / Build `25953419`, read [game-1.06-upgrade.md](game-1.06-upgrade.md): x64 Doorstop restored injection while the existing managed BepInEx core and two tested plugins were retained. A managed plugin's PE container alone does not establish a 32-bit requirement; inspect CLR flags and dependencies, then verify its functions.

## Archive installation

Before merging a Mod archive:

1. Reject absolute paths and `..` traversal.
2. Inspect x86/x64 architecture for native DLLs.
3. List collisions against the game root.
4. Copy only replaced files into a timestamped backup.
5. Verify extracted files by hash.
6. Treat bundled logs as untrusted historical artifacts.

## Doorstop

The verified Wine setup required a `Mortal.exe` application-level override:

```text
winhttp = native,builtin
```

Confirm local `winhttp.dll` and the BepInEx preloader assembly in the current process.

## Unstripped corlibs

Historical Build `20337760` verified sizes (recheck Unity and corlibs for the current build):

- game `Mortal_Data/Managed/mscorlib.dll`: `3,906,048` bytes;
- matching Unity 2020.3.49 full `mscorlib.dll`: `4,065,792` bytes.

Place legally obtained, version-matched corlibs under `BepInEx/unstripped_corlib` and configure:

```ini
[General]
enabled = true
target_assembly = BepInEx\core\BepInEx.Unity.Mono.Preloader.dll

[UnityMono]
dll_search_path_override = "BepInEx\unstripped_corlib;BepInEx\core"
```

Do not download or redistribute corlibs from an unverified third party. Require an exact Unity version match.

## BepInEx Wine preloader failure

The relevant exception is:

```text
Cannot set the value of PlatformHelper.Current once it has been accessed.
```

BepInEx issue `#1201` and PR `#1254` document the Wine fix. The field-tested x86 Mono build is `6.0.0-be.785`. Back up the full existing `BepInEx/core` before replacement.

Keep the default `Application::.cctor` entry point. BepInEx can create the static constructor when absent.

## Verification

Require a log written by the current launch. Check its modification time and find:

- BepInEx version;
- Wine platform and process bitness matching the current executable;
- `Chainloader initialized`;
- every expected plugin's load or initialization line;
- Error/Fatal output.
