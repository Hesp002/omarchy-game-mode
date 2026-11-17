# omarchy-game-mode

SteamOS-style Game Mode (gamescope + Steam Big Picture) started from a spare TTY,
with Hyprland left running on tty2.

    ./install.sh [--with-mangohud]    # steam, gamescope, lib32 radeon drivers; links game-mode
    Ctrl+Alt+F3 → log in → game-mode
    Steam ▸ Power ▸ Switch to Desktop  → Steam quits, back at the TTY → Ctrl+Alt+F2
    ./uninstall.sh [--packages]

- `game-mode` refuses to run inside Hyprland, shuts down a desktop Steam first, and holds a
  logind idle/sleep/lid inhibitor while running (the backgrounded desktop sees no input).
- `shims/` stand in for SteamOS helpers that `-steamos3` Steam calls
  (session-select, update, BIOS update, branch select). Prepended to PATH only in game mode.
- Extra gamescope flags: `GAMESCOPE_ARGS="..."` in `~/.config/omarchy-game-mode.conf`.
