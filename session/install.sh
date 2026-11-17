#!/usr/bin/env bash
# Install SteamOS-style Game Mode as a separate SDDM session on Omarchy.
#
#   ./install.sh [--boot-to game|desktop|greeter] [--desktop-login autologin|greeter]
#                [--user NAME] [--with-mangohud]
#
#   --boot-to        what the machine logs into at boot (default: game, like SteamOS)
#   --desktop-login  "Switch to Desktop" logs straight in (autologin, default) or shows
#                    the SDDM greeter (greeter: needed if your keyring has a password)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
LIB=/usr/local/lib/omarchy-gamemode

boot_to=game desktop_login=autologin user=${SUDO_USER:-$USER} mangohud=0
while (($#)); do
  case $1 in
    --boot-to)       boot_to=$2; shift 2 ;;
    --desktop-login) desktop_login=$2; shift 2 ;;
    --user)          user=$2; shift 2 ;;
    --with-mangohud) mangohud=1; shift ;;
    -h|--help)       sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[[ $boot_to =~ ^(game|desktop|greeter)$ ]]     || { echo "--boot-to: game|desktop|greeter" >&2; exit 2; }
[[ $desktop_login =~ ^(autologin|greeter)$ ]]  || { echo "--desktop-login: autologin|greeter" >&2; exit 2; }
id "$user" >/dev/null 2>&1                     || { echo "no such user: $user" >&2; exit 2; }
[[ $EUID -ne 0 ]] || { echo "Run as your normal user (it uses sudo where needed)." >&2; exit 1; }

source "$here/../lib/common.sh"
source "$here/../lib/gpu-packages.sh"

echo "Installing Game Mode (session variant) for user $user."
echo "sudo will ask for your password when it's first needed."

step "Checking the system"
systemctl is-enabled sddm >/dev/null 2>&1 || { echo "SDDM isn't the display manager; this script needs it." >&2; exit 1; }
info "Display manager: SDDM"
grep -q '^\[multilib\]' /etc/pacman.conf || { echo "Enable [multilib] in /etc/pacman.conf first (Steam is 32-bit)." >&2; exit 1; }
info "multilib repository: enabled"
for s in hyprland-uwsm.desktop hyprland.desktop; do
  [[ -f /usr/share/wayland-sessions/$s ]] && { desktop_session=$s; break; }
done
[[ -n ${desktop_session:-} ]] || { echo "No Hyprland session file found in /usr/share/wayland-sessions." >&2; exit 1; }
info "Desktop session: $desktop_session"
if grep -qs '^\[Autologin\]' /etc/sddm.conf; then
  warn "/etc/sddm.conf has an [Autologin] section; it may override Game Mode switching."
  warn "Move it into /etc/sddm.conf.d/ (lower priority) if switching doesn't work."
fi

step "Detecting graphics hardware"
pkgs=(steam gamescope)
((mangohud)) && pkgs+=(mangohud lib32-mangohud)
NVIDIA_PRESENT=0
add_gpu_packages
if ((NVIDIA_PRESENT)) && [[ $(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null) != Y ]]; then
  warn "nvidia_drm.modeset isn't enabled; gamescope needs it (Omarchy normally sets it)."
fi

step "Installing packages"
install_missing_packages "$here/.installed-packages"

step "Installing Game Mode files"
info "$LIB (session launcher, switch helper, SteamOS helper stand-ins)"
sudo install -d -m 755 "$LIB" "$LIB/bin"
sudo install -m 755 "$here/files/session"     "$LIB/session"
sudo install -m 755 "$here/files/set-session" "$LIB/set-session"
sudo install -m 755 "$here"/files/bin/*       "$LIB/bin/"
info "/usr/local/bin/omarchy-gamemode (switch from the desktop)"
sudo install -m 755 "$here/files/omarchy-gamemode" /usr/local/bin/omarchy-gamemode
info "/usr/share/wayland-sessions/omarchy-gamemode.desktop (login session)"
sudo install -m 644 "$here/files/omarchy-gamemode.desktop" /usr/share/wayland-sessions/omarchy-gamemode.desktop
info "/usr/local/share/applications/omarchy-gamemode.desktop (\"Game Mode\" launcher entry)"
sudo install -D -m 644 "$here/files/omarchy-gamemode-launcher.desktop" \
  /usr/local/share/applications/omarchy-gamemode.desktop

step "Saving settings"
info "/etc/omarchy-gamemode.conf"
sudo tee /etc/omarchy-gamemode.conf >/dev/null <<CONF
# omarchy-game-mode settings. Change BOOT_TO with:
#   sudo $LIB/set-session --boot game|desktop|greeter
USER_NAME=$user
BOOT_TO=$boot_to
DESKTOP_LOGIN=$desktop_login
DESKTOP_SESSION=$desktop_session
CONF

step "Allowing passwordless session switching"
info "/etc/sudoers.d/omarchy-gamemode (only 'set-session game' and 'set-session desktop')"
tmp=$(mktemp)
cat > "$tmp" <<SUDO
$user ALL=(root) NOPASSWD: $LIB/set-session game, $LIB/set-session desktop
SUDO
sudo visudo -cqf "$tmp" || { rm -f "$tmp"; echo "sudoers rule failed validation" >&2; exit 1; }
sudo install -m 440 "$tmp" /etc/sudoers.d/omarchy-gamemode
rm -f "$tmp"

step "Setting what the next boot logs into"
sudo "$LIB/set-session" --reset
info "/etc/sddm.conf.d/zz-omarchy-gamemode.conf → $boot_to"

cat <<DONE

${_b}Game Mode installed.${_r}
  Boots into:          $boot_to   (change: sudo $LIB/set-session --boot game|desktop|greeter)
  Switch to Desktop:   $([[ $desktop_login == greeter ]] && echo "password screen, then $desktop_session" || echo "straight into $desktop_session")
  From the desktop:    "Game Mode" in the app launcher, or run omarchy-gamemode
  From Game Mode:      Steam ▸ Power ▸ Switch to Desktop
  Takes effect on the next reboot or switch; nothing restarted now.

  Tip: start Steam once on the desktop and sign in first. Its first start downloads a few
  hundred MB of updates, which otherwise happens on a mostly black screen in Game Mode.
DONE
