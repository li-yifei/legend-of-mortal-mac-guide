# Runtime operations

## Steam Overlay input lock

The verified environment showed Overlay input hooks unloading and reattaching around app switches, followed by frozen input or rendering. Disable the global Steam Overlay and the game's per-title Overlay. Verify the Overlay process remains absent.

## Sleep, wake, lock, and displays

DXMT/Metal window surfaces and Wine CoreAudio endpoints can become stale across lid sleep, unlock, or display hot-plug events. Use `caffeinate` while playing. After a display topology or sleep transition, a full refresh of the game, Windows Steam, and the wrapper's wineserver provides the strongest recovery.

Keep a running game intact during diagnosis unless the user authorizes a restart.

## Stale Steam session

Two observed sessions stopped accepting `-applaunch 1859910` after roughly 33–35 hours. The launcher submitted a request and Steam wrote no new game launch record.

Confirm:

- no live `Mortal.exe`;
- Steam and wineserver age;
- absence of a new entry in `gameprocess_log.txt`;
- launcher command and target prefix.

An authorized recovery should exit Windows Steam, stop only the exact wrapper's wineserver, and relaunch the wrapper.

## Audio after wake

Wine CoreAudio can retain the pre-sleep Bluetooth endpoint while macOS rebuilds the default output device. Correlate Unity/Wwise initialization, Wine CoreAudio warnings, output-device changes, and wake time before recommending a session refresh.

## Window position and fullscreen

Multi-display coordinates can leave the Unity window outside the visible desktop. Read current window bounds and display layout before moving it. Wine fullscreen windows can cover the macOS menu bar through a raised window level; a borderless window is the stable practical mode.
