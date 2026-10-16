# Horizon graphics milestone

Version: 0.2.0-alpha.1

## Implemented

A lit 3D park with a physical sky, shadowed track structures, sculpted coaster car, station, promenade, animated lake, smooth terrain, and instanced forest that stays clear of the edited track.

The rendering remains separate from the gameplay model. The two-dimensional games retain their logical coordinates, movement, collision geometry and saved-progress formats. `scripts/future_paint.gd` provides smooth gradients, soft radial light, beveled surfaces and common typography. Glow uses a reusable procedural texture rather than repeated blur passes. Coaster scenery batches its forest meshes.

## Verification

Godot 4.5.1 Standard and matching Linux templates. Use the repository's local packaging and test commands. This milestone is checked through headless model/input/flow tests, local Linux export, exported-program smoke launches and 1280×800 graphical captures. `tools/capture_gameplay.gd` starts the real gameplay scene and captures a live viewport; it does not replace the game's renderer with a mockup.

Physical Steam Deck / UltraStik playtesting and on-device frame-rate acceptance remain pending. The screenshots use a software renderer; they are not measurements of Steam Deck GPU performance. Audio playback tests requiring a real audio mixer are outside this graphics milestone. No GitHub Actions, metered runners or Actions artifacts are required.

## Delivery

Keep the downloaded versioned ZIP unextracted in Downloads, close the game and use its existing desktop Update icon. New installations use the matching one-time updater installer. Saves and settings remain outside the installation directory. This alpha is a first visual modernization milestone; further art direction, polish and hardware tuning remain open.
