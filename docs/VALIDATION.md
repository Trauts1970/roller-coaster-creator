# Local validation — 0.1.0

Verified on 2026-10-15 UTC using official Godot 4.5.1 stable on Linux x86_64.

- Editor import: passed.
- `tests/test_track.gd`: passed. Checks centerline continuity and sampling,
  demo traversal, gravity acceleration, unpowered stall, terrain collision,
  empty/unknown track rejection and turn direction.
- `tests/test_scene.gd`: passed. Instantiates main scene, checks touch panel
  height at 1280×800, reorders sections, saves/loads a layout, rejects invalid
  saved sections without replacing the active layout, runs to the endpoint,
  and switches camera. Restores any existing user save afterward.
- Local Linux release export: passed, using matching 4.5.1 Linux templates.
- Exported standalone executable: headless 120-frame launch passed without
  script/runtime errors.
- Demo peak speed: approximately 21.33 m/s (76.8 km/h). Traversable but reports
  excessive loads. Unbanked turns are not labelled safe.

The point-mass model is illustrative and is not independently validated coaster
physics. Game thresholds are vertical -1 to +4.5 g and lateral <=1.5 g, not an
engineering standard. Finite train, structure and wheel-contact dynamics are absent.

Visual inspection was not completed: virtual display connections failed on this
host. Headless execution does not verify visual quality. Physical Steam Deck
controller, touch, performance and installation testing remain pending.
No GitHub Actions run, Actions artifact or public release was created.

Next: graphical inspection, banked turns and a safer demo, optional manual 3D
editing, intersection/closure checks, then a versioned Deck installer/updater
that preserves user data. Only user confirmation can complete Deck playtesting.
