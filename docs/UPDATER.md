# Roller Coaster Creator — Steam Deck updates

This package uses the same download-and-click method as NeonMaze.

1. Download `RollerCoasterCreator-v0.1.1-SteamDeck.zip` and leave it unextracted in Downloads.
2. Close Roller Coaster Creator.
3. Run `Install-Roller-Coaster-Creator-Updater.desktop` once in Desktop Mode. Allow execution if Dolphin asks. The installer creates **Update Roller Coaster Creator** and installs the downloaded ZIP.
4. For later versions, download the new ZIP, close the game, and click **Update Roller Coaster Creator**.

The installer reads existing Steam shortcuts to preserve the current binary or launcher target; it never edits Steam settings. With no existing install it uses `~/Games/RollerCoasterCreator`. Add `RollerCoasterCreator.x86_64` there to Steam once as a Non-Steam game, without forcing Proton. The updater retains that location, makes the executable runnable, and keeps backups. Godot saves/settings outside the install directory and unrelated files are retained.

Close the running game before updating. Archives are checked for game identity, version, Linux architecture, contents, size, and CRC. Failed replacements roll back. A newer ZIP wins even when an older download has a newer timestamp.

This is a development build. Automated checks do not confirm physical Steam Deck, UltraStik, graphics, audio, or gameplay acceptance. Publishing a package does not automatically connect it to Game Workshop downloads.

Developers: `GODOT_BIN=/path/to/godot python3 tools/package_steamdeck.py`. Requires matching Linux export templates. Existing tar.gz packaging is retained separately.
