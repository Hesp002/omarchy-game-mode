# omarchy-game-mode

SteamOS / Bazzite-style Game Mode for Omarchy: Steam's gamepad UI running in gamescope,
with switching between it and the Hyprland desktop. Two variants:

| | `session/` (full) | `tty/` (light) |
|---|---|---|
| How you enter | boots straight in, or "Game Mode" in the launcher | Ctrl+Alt+F3 → log in → `game-mode` |
| Switch to Desktop | Steam ▸ Power ▸ Switch to Desktop logs into Hyprland | Steam quits → Ctrl+Alt+F2 |
| System changes | SDDM session + autologin override, sudoers rule, `/usr/local` | none outside `~` (plus packages) |

Both install Steam, gamescope and the Vulkan drivers for every GPU found (`lib/gpu-packages.sh`:
AMD/Intel Mesa, NVIDIA 32-bit userspace matching the installed driver), and both have an
uninstall script (`--packages` also removes what the installer added).

## Quick install

    # full session variant (boots into Game Mode)
    curl -fsSL https://raw.githubusercontent.com/Hesp002/omarchy-game-mode/main/bootstrap.sh | bash

    # with options / the tty variant / uninstall
    curl -fsSL https://raw.githubusercontent.com/Hesp002/omarchy-game-mode/main/bootstrap.sh | bash -s -- install session --boot-to desktop --desktop-login greeter
    curl -fsSL https://raw.githubusercontent.com/Hesp002/omarchy-game-mode/main/bootstrap.sh | bash -s -- install tty
    curl -fsSL https://raw.githubusercontent.com/Hesp002/omarchy-game-mode/main/bootstrap.sh | bash -s -- uninstall session --packages

The bootstrap keeps the downloaded repo in `~/.local/share/omarchy-game-mode-src` (uninstall
needs it) and then runs the variant's `install.sh` with your options. Pin a version with
`OGM_REF=<tag|commit>`. Prefer to read before running? `git clone` the repo and run
`session/install.sh` or `tty/install.sh` directly; it does the same thing.

## session/ — how it works

    ./install.sh [--boot-to game|desktop|greeter] [--desktop-login autologin|greeter] [--with-mangohud]

- `/usr/share/wayland-sessions/omarchy-gamemode.desktop` → `/usr/local/lib/omarchy-gamemode/session`
  (`gamescope -e … -- steam -gamepadui -steamos3`), selectable in the SDDM greeter too.
- `set-session` (root, whitelisted in `/etc/sudoers.d/omarchy-gamemode` for exactly
  `game` and `desktop`) writes `/etc/sddm.conf.d/zz-omarchy-gamemode.conf`, then from a transient
  systemd unit waits ≤30 s for Steam to quit, restarts SDDM (which autologins into the target),
  and 10 s later restores the boot default.
- Steam's "Switch to Desktop" calls `steamos-session-select` → `set-session desktop`.
- Desktop → Game Mode: `omarchy-gamemode` (also a "Game Mode" launcher entry). This logs out of
  Hyprland without asking, like SteamOS.
- `--desktop-login greeter` shows the SDDM password prompt on the way back to the desktop, so a
  password-protected gnome-keyring is unlocked (autologin can't unlock it).
- Change the boot target later: `sudo /usr/local/lib/omarchy-gamemode/set-session --boot …`
- Per-user gamescope flags: `GAMESCOPE_ARGS="…"` in `~/.config/omarchy-gamemode.conf`.

Stand-ins for the SteamOS helpers Steam calls in `-steamos3` mode live in
`/usr/local/lib/omarchy-gamemode/bin` (on PATH only inside the session):
`steamos-session-select` (switch), `steamos-update` (always "no update", exit 7),
`jupiter-biosupdate` (no-op), `steamos-select-branch` (always "stable").
