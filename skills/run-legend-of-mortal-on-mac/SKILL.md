---
name: run-legend-of-mortal-on-mac
description: Diagnose, install, or repair Legend of Mortal on Apple Silicon macOS through Sikarugir, Wine, Windows Steam, DXMT, Wine fonts, Doorstop, and BepInEx. Use for game startup, D3D11, missing money text, Mod loading, Retina, input, sleep/wake, audio, or stale Steam-session symptoms. Keep save analysis and gameplay guidance outside this skill.
---

# Run Legend of Mortal on Mac

Treat the wrapper, prefix, Steam installation, game directory, renderer modules, and Mods as user data. Establish evidence before changing them.

## Scope and authorization

- For explanation or diagnosis, perform read-only inspection and report the first failing layer. Do not implement a fix.
- For install or repair requests, make the smallest reversible change inside the exact wrapper placed in scope by the user.
- Keep real save files read-only. Do not copy them into this repository, logs, public issues, or fixtures.
- Obtain explicit authorization before stopping a running game, restarting Steam/Wine, replacing renderer modules, installing fonts, editing the registry, or changing game/Mod files when the user's request has not already authorized that action.
- Keep other Wine, Whisky, CrossOver, and Sikarugir wrappers outside the operation.
- Use official project sources and record downloaded file versions and hashes. Do not redistribute game files, fonts, Unity corlibs, Steam, Wine engines, or Mod archives.

## Start with read-only inspection

Resolve the exact wrapper and run:

```bash
scripts/inspect-lom-wrapper.sh "/path/to/SteamWin.app"
```

Record:

- Steam Build ID and Unity version;
- `Mortal.exe` architecture;
- active Wine engine and prefix;
- renderer module paths and SHA-256;
- `RetinaMode`, DLL overrides, and Unity resolution values;
- font file count;
- Doorstop, BepInEx, and Chainloader evidence;
- current Steam, Wine, and game processes.

Read [references/verified-case.md](references/verified-case.md) when comparing against the known-good stack.

## Route by the first failing layer

1. **Wrapper or Windows Steam startup**: read [references/install-renderer.md](references/install-renderer.md). Separate Steam transport/webhelper failures from game graphics failures.
2. **`Failed to initialize graphics` or D3D11 device creation**: read [references/install-renderer.md](references/install-renderer.md). Trust loaded modules and `Player.log` over wrapper toggles.
3. **Missing shop price or money totals**: read [references/font-repair.md](references/font-repair.md). Confirm the symptom and prefix font state before installing a broad font set.
4. **BepInEx files present and plugins absent**: read [references/mod-repair.md](references/mod-repair.md). Trace Doorstop → Preloader → Chainloader → Plugin.
5. **Input lock, sleep/wake freeze, lost audio, external-display trouble, or repeated launch failure**: read [references/runtime-operations.md](references/runtime-operations.md).

## Change protocol

Before an authorized mutation:

1. Confirm the game, Steam, and wineserver state.
2. Resolve exact files with literal paths; avoid unresolved globs for replacement targets.
3. Create a timestamped backup beside the component being changed.
4. Record original size, modification time, and SHA-256 for binaries and configuration files.
5. Change one causal layer at a time.
6. Restart the narrowest affected process.
7. Verify through two independent signals when possible, such as module-load evidence plus `Player.log`.
8. Report the backup path and a concrete rollback procedure.

## Success criteria

Renderer success requires Unity D3D11 initialization and the intended DXMT modules loaded from the active search path.

Font success requires registered font files plus an in-game check of shop price and total text.

Mod success requires a newly written log from the current launch, `Chainloader initialized`, and each expected plugin's load or initialization entry.

For every conclusion, report game version, conditions, result, evidence, and confidence.
