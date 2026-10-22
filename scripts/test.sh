#!/usr/bin/env bash
# Runs the headless gdUnit4 test suite. Set GODOT to override the Godot binary.
set -u
cd "$(dirname "$0")/.."

GODOT="${GODOT:-$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"

# Refresh the script class cache so class_name types resolve on a fresh clone.
"$GODOT" --headless --path . --import >/dev/null 2>&1

"$GODOT" --headless --path . -s \
	res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
	--ignoreHeadlessMode -c -a res://test "$@"
status=$?

"$GODOT" --headless --path . --quiet -s res://addons/gdUnit4/bin/GdUnitCopyLog.gd >/dev/null 2>&1
exit $status
