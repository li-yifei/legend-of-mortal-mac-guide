# Font repair workflow

## Target symptom

The verified symptom showed Chinese text, ordinary numbers, and currency icons while shop price and total fields were empty.

Unity asset inspection found `MoneyValue` and `MoneyText` bound to embedded `SourceHanSerifTC-Bold`. The default value contained `50`, and the font asset contained the required digit glyphs. The Wine prefix contained only two physical font files.

## Repair

For diagnosis, count physical files under `drive_c/windows/Fonts` and inspect Windows font mappings.

For an authorized repair:

1. Exit the game, Windows Steam, and the wrapper's wineserver.
2. Back up `drive_c/windows/Fonts`, `system.reg`, `user.reg`, and `userdef.reg`.
3. Record file metadata and hashes for the registry hives.
4. Use the wrapper's Winetricks environment to install `fonts → allfonts`.
5. Verify font files and registry mappings.
6. Restart Steam and the game.
7. Ask the user to verify shop price and total text.

The verified environment grew from 2 font files to 121, approximately 284 MB.

Do not commit, upload, or redistribute installed fonts. Keep their original download and license paths.
