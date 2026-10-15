# Roller Coaster Creator

Steam Deck-first Godot 4 roller coaster construction prototype. Version **0.1.0**.
Development stays on `dev/roller-coaster-v0.1`; `main` carries Game Workshop status separately.

## Implemented prototype

- Automatic sequential assembly is the default: station, chain lift, crest, drop,
  valley, straights, left/right turns, uphill sections and brakes.
- Add, remove and reorder sections; the centerline rebuilds automatically.
- Procedural 3D rails, sleepers, supports, terrain and cart; overview and front-seat cameras.
- Gravity, simple rolling/aerodynamic losses, powered lift, braking, stall and terrain checks.
- Vertical/lateral load estimates distinguish reaching the endpoint from passing prototype load limits.
- Save/load one layout in Godot's `user://track.json`, outside the install directory.
- Large touch buttons and initial controller shortcuts.

## Run and build locally

Use **Godot 4.5.1** with matching Linux export templates. Import `project.godot`
and press Run, or run `godot --path .`. For tests and a Linux x86_64 export:

```sh
GODOT_BIN=/path/to/godot ./scripts/build_local.sh
```

The ignored `build/` folder contains the executable with embedded resources.
No workflows or Actions artifacts are used. Build binaries are not committed.

Touch: choose a section and Add; select a row to move/remove it. Test restarts the
cart, Camera toggles views. Mouse: right-drag orbits, wheel zooms. Controller:
A tests, Y switches camera, X adds a straight, B stops; D-pad orbits/zooms.
Touch controls provide the full layout editing flow. Full controller editor
navigation remains unfinished. Steam Input should expose a gamepad for shortcuts.

## Known limits and next milestone

This is an open-track, constrained point-mass prototype, not an engineering simulator.
Sections join positionally with interpolated pitch; turns are unbanked. The demo
reaches the endpoint but exceeds the illustrative passenger-load limit. The model
uses local centerline curvature, not a finite train, wheel contact, structural
analysis, derailment dynamics or a validated human tolerance standard. No automatic
loop closure, track self-collision detection or return station exists yet.

Manual 3D editing remains planned as the second construction method. Sound,
polished artwork, controller-complete editing, Steam Deck updater integration and
physical Steam Deck testing are unfinished. No downloadable release is published.
Next: banked turns and safer demo, then manual editing and a verified Deck package.

See `docs/VALIDATION.md` for verified local results and their limits.
