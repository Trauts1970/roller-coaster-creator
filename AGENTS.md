# Game Workshop reporting and branch safety

Work only in Trauts1970/roller-coaster-creator. Keep unfinished game code on dev/roller-coaster-v0.1; main holds dashboard status and stable documentation. After meaningful saved milestones, update .game-workshop/status.json on main without merging unfinished code. Preserve concurrent changes; inspect current refs before writes.

Report verified facts only. Allowed checklist values: Unverified, Needed, In progress, Ready to test, Complete. A successful code build does not mean a Steam Deck playtest passed; only mark it Complete after user confirmation. Never invent build versions or download URLs.

Avoid GitHub Actions entirely by default. Do not add workflows or upload Actions artifacts without explicit authorization. Prefer local Godot builds and versioned releases for tested packages. Preserve saves/settings across installs. Keep Game Workshop updates lightweight.
