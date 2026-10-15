#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-godot}"
"$GODOT_BIN" --headless --path . --editor --import --quit
"$GODOT_BIN" --headless --path . --script tests/test_track.gd
"$GODOT_BIN" --headless --path . --script tests/test_scene.gd
mkdir -p build
"$GODOT_BIN" --headless --path . --export-release Linux build/RollerCoasterCreator.x86_64
chmod +x build/RollerCoasterCreator.x86_64
"$PWD/build/RollerCoasterCreator.x86_64" --headless --quit-after 120
