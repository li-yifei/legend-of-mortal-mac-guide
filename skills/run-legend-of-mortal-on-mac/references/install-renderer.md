# Install and renderer workflow

## Install baseline

Use an independent Sikarugir wrapper. Initialize its prefix, install `cjkfonts`, apply `hidewineexports=enable`, install Windows Steam, and install AppID `1859910`.

Preserve the Windows Steam directory when changing a prefix or engine. Copy it only after the source and destination Steam/Wine processes have exited.

An x86 Steam bootstrap is normal. Inspect `Mortal.exe` directly. Historical Build `20337760` is PE32 and uses the 32-bit D3D11 path. Game 1.06 / Build `25953419` is PE32+ x64; read [game-1.06-upgrade.md](game-1.06-upgrade.md) for that verified setup.

## Classify startup failures

- Steam transport or webhelper error with no game launch record: investigate Steam/engine compatibility and stale sessions.
- `InitializeEngineGraphics failed` or `d3d11: failed to create device`: investigate renderer selection and DLL search order.
- Forced OpenGL reports an unavailable graphics device: stop that route.
- Unity reaches D3D11, assembly reload, scene, or audio initialization: graphics initialization succeeded; investigate the later failure.

## DXMT runtime verification

Historical Build `20337760` uses 32-bit DXMT. Resolve the current game architecture and active module paths afresh for every update. Wrapper settings can coexist with WineD3D modules loaded from the engine directory.

Verify with:

- `WINEDEBUG=+loaddll`;
- SHA-256 of active engine modules;
- process-open module paths;
- Unity `Player.log`.

When an authorized repair is required, back up the active engine modules before placing matching DXMT files into the actual search paths:

- `d3d10core.dll`;
- `d3d11.dll`;
- `dxgi.dll`;
- `winemetal.dll`;
- matching Unix `winemetal.so`.

Resolve the directory from runtime evidence. Common directory names include `i386-windows` and an architecture-specific Unix module directory.

Launch through `steam.exe -applaunch 1859910` after a direct executable diagnostic.

## Retina

`HKCU\Software\Wine\Mac Driver\RetinaMode = "Y"` enables Wine Retina mode. Unity UI scaling remains separate. Prefer the game's resolution selector and remove forced width/height flags after the user chooses a practical size.
