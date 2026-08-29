#!/bin/zsh
set -u

usage() {
  print -u2 "usage: $0 /path/to/SteamWin.app [relative/path/to/Mortal.exe]"
}

section() {
  print
  print "## $1"
}

show_file() {
  local target="$1"
  if [[ -f "$target" ]]; then
    file "$target"
    shasum -a 256 "$target"
  else
    print "missing=$target"
  fi
}

if (( $# < 1 || $# > 2 )); then
  usage
  exit 2
fi

wrapper="${1:A}"
game_rel="${2:-drive_c/Program Files (x86)/Steam/steamapps/common/LegendOfMortal/Mortal.exe}"
contents="$wrapper/Contents"
shared="$contents/SharedSupport"
prefix="$shared/prefix"
engine="$shared/wswine.bundle"
game="$prefix/$game_rel"
game_root="${game:h}"
steam_root="$prefix/drive_c/Program Files (x86)/Steam"
manifest="$steam_root/steamapps/appmanifest_1859910.acf"

section "Resolved paths"
print "wrapper=$wrapper"
print "prefix=$prefix"
print "engine=$engine"
print "game=$game"

if [[ ! -d "$wrapper" || ! -d "$contents" ]]; then
  print -u2 "error=wrapper_not_found_or_invalid"
  exit 1
fi

section "Wrapper and engine"
for target in \
  "$contents/Info.plist" \
  "$engine/bin/wine" \
  "$engine/bin/wineserver" \
  "$prefix/system.reg" \
  "$prefix/user.reg" \
  "$prefix/userdef.reg"; do
  if [[ -e "$target" ]]; then
    print "present=$target"
  else
    print "missing=$target"
  fi
done

if [[ -x "$engine/bin/wine" ]]; then
  "$engine/bin/wine" --version 2>/dev/null || true
fi

section "Steam manifest"
if [[ -f "$manifest" ]]; then
  rg '"(appid|name|buildid|LastUpdated|StateFlags)"' "$manifest" || true
else
  print "missing=$manifest"
fi

section "Game executable"
show_file "$game"

section "Unity version and renderer"
player_logs=(${prefix}/drive_c/users/*/AppData/LocalLow/*/*/Player.log(N.om))
if (( ${#player_logs} > 0 )); then
  player_log="$player_logs[1]"
  print "player_log=$player_log"
  rg -m 20 'Initialize engine version|Direct3D:|Version:  Direct3D|Renderer:|InitializeEngineGraphics|failed to create device|Begin MonoManager ReloadAssembly' "$player_log" || true
else
  print "player_log=missing"
fi

section "Renderer modules"
for arch in i386-windows x86_64-windows i386-unix x86_64-unix; do
  for module in d3d10core.dll d3d11.dll dxgi.dll winemetal.dll winemetal.so; do
    module_path="$engine/lib/wine/$arch/$module"
    if [[ -f "$module_path" ]]; then
      show_file "$module_path"
    fi
  done
done

section "Registry evidence"
if [[ -f "$prefix/user.reg" ]]; then
  rg -n 'RetinaMode|LogPixels|DllOverrides|winhttp|d3d11|dxgi|Screenmanager Resolution|Screenmanager Fullscreen' "$prefix/user.reg" || true
fi

section "Fonts"
fonts_dir="$prefix/drive_c/windows/Fonts"
if [[ -d "$fonts_dir" ]]; then
  font_count=$(find "$fonts_dir" -maxdepth 1 -type f | wc -l | tr -d ' ')
  print "font_count=$font_count"
  du -sh "$fonts_dir" 2>/dev/null || true
else
  print "missing=$fonts_dir"
fi

section "Doorstop and BepInEx"
for target in \
  "$game_root/winhttp.dll" \
  "$game_root/doorstop_config.ini" \
  "$game_root/BepInEx/core/BepInEx.Unity.Mono.Preloader.dll" \
  "$game_root/BepInEx/unstripped_corlib/mscorlib.dll"; do
  if [[ -f "$target" ]]; then
    show_file "$target"
  else
    print "missing=$target"
  fi
done

doorstop_config="$game_root/doorstop_config.ini"
if [[ -f "$doorstop_config" ]]; then
  rg -n 'enabled|target_assembly|dll_search_path_override' "$doorstop_config" || true
fi

bepinex_log="$game_root/BepInEx/LogOutput.log"
if [[ -f "$bepinex_log" ]]; then
  print "bepinex_log=$bepinex_log"
  ls -l "$bepinex_log"
  rg -m 60 'BepInEx [0-9]|System platform|Process bitness|Chainloader initialized|Loaded plugin|Loading \[|Error|Fatal|PlatformHelper' "$bepinex_log" || true
else
  print "bepinex_log=missing"
fi

section "Current processes"
ps axo pid=,etime=,args= |
  rg 'steam\.exe|steamwebhelper\.exe|Mortal\.exe|UnityCrashHandler|wineserver' |
  rg -v 'inspect-lom-wrapper|rg ' || true

section "Safety"
print "mode=read_only"
print "files_modified=0"
print "wine_steam_game_sessions_started_or_stopped=0"
