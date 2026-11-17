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
`OGM_REF` (see [Environment variables](#environment-variables)). Prefer to read before running? `git clone` the repo and run
`session/install.sh` or `tty/install.sh` directly; it does the same thing.

## Options

    curl -fsSL …/bootstrap.sh | bash -s -- [install|uninstall] [session|tty] [installer options]

- `bash -s --`: `-s` makes bash run the script it reads from the pipe, and `--` passes
  everything after it to `bootstrap.sh`. Only needed when you give options; plain `| bash`
  installs the full session variant with the defaults.
- `install` (default) or `uninstall`.
- `session` (default): the full separate login session. `tty`: the light variant you start
  from a spare console.
- Anything after that goes to the variant's `install.sh` / `uninstall.sh`. Running the
  installer directly from a clone takes the same options.

### session/install.sh

| Option | Values | Meaning |
|---|---|---|
| `--boot-to` | `game` (default), `desktop`, `greeter` | What happens at startup: log into Game Mode (like SteamOS), into the desktop (following `--desktop-login`), or always show the SDDM login screen. |
| `--desktop-login` | `autologin` (default), `greeter` | How you get into the desktop, both from Steam ▸ Switch to Desktop and with `--boot-to desktop`: straight into Hyprland, or the SDDM password screen first. Use `greeter` if gnome-keyring has a password, because autologin can't unlock it. |
| `--user` | a username | Who is logged in automatically and allowed to switch sessions without a password. Defaults to whoever runs the installer. |
| `--with-mangohud` | — | Also installs MangoHud, the FPS/performance overlay you can turn on from Steam's quick menu. |
| `-h`, `--help` | — | Print the options. |

How `--boot-to` and `--desktop-login` combine (going from the desktop into Game Mode always
logs in automatically):

| `--boot-to` | `--desktop-login` | At startup | Steam ▸ Switch to Desktop |
|---|---|---|---|
| `game` | `autologin` | Straight into Game Mode | Straight into Hyprland (exactly like SteamOS) |
| `game` | `greeter` | Straight into Game Mode | Password screen, then Hyprland |
| `desktop` | `autologin` | Straight into Hyprland | Straight into Hyprland |
| `desktop` | `greeter` | Password screen | Password screen |
| `greeter` | `autologin` | Password screen; pick Game Mode or Hyprland | Straight into Hyprland |
| `greeter` | `greeter` | Password screen | Password screen |

`--boot-to greeter` suits shared or security-minded machines: nothing logs in until someone
types a password. `--desktop-login greeter` is for password-protected keyrings: the desktop
always asks for the password, while booting into Game Mode can still skip it.
`--boot-to desktop --desktop-login greeter` behaves the same at startup as `--boot-to greeter`.

Change the boot target after installing with
`sudo /usr/local/lib/omarchy-gamemode/set-session --boot game|desktop|greeter`.

### tty/install.sh

| Option | Meaning |
|---|---|
| `--with-mangohud` | Also installs MangoHud, the FPS/performance overlay you can turn on from Steam's quick menu. |

### uninstall.sh (both variants)

| Option | Meaning |
|---|---|
| `--packages` | Also removes the packages the installer added. Packages that were already installed are left alone. |

### Environment variables

| Variable | Meaning |
|---|---|
| `OGM_REF` | Branch, tag or commit for `bootstrap.sh` to download instead of `main`. It applies to `bash`, so set it after the pipe: `curl … \| OGM_REF=v1.0 bash` |

## session/ — how it works

- `/usr/share/wayland-sessions/omarchy-gamemode.desktop` → `/usr/local/lib/omarchy-gamemode/session`
  (`gamescope -e … -- steam -gamepadui -steamos3`), selectable in the SDDM greeter too.
- `set-session` (root, whitelisted in `/etc/sudoers.d/omarchy-gamemode` for exactly
  `game` and `desktop`) writes `/etc/sddm.conf.d/zz-omarchy-gamemode.conf`, then from a transient
  systemd unit waits ≤30 s for Steam to quit, restarts SDDM (which autologins into the target),
  and 10 s later restores the boot default.
- Steam's "Switch to Desktop" calls `steamos-session-select` → `set-session desktop`.
- Desktop → Game Mode: `omarchy-gamemode` (also a "Game Mode" launcher entry). This logs out of
  Hyprland without asking, like SteamOS.
- Per-user gamescope flags: `GAMESCOPE_ARGS="…"` in `~/.config/omarchy-gamemode.conf`.

Stand-ins for the SteamOS helpers Steam calls in `-steamos3` mode live in
`/usr/local/lib/omarchy-gamemode/bin` (on PATH only inside the session):
`steamos-session-select` (switch), `steamos-update` (always "no update", exit 7),
`jupiter-biosupdate` (no-op), `steamos-select-branch` (always "stable").
