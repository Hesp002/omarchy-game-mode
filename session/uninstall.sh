#!/usr/bin/env bash
# Undo install.sh. --packages also removes the packages install.sh added.
# Nothing is restarted; SDDM's normal (Omarchy) autologin behaviour returns on next boot.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
LIB=/usr/local/lib/omarchy-gamemode

sudo rm -f /etc/sudoers.d/omarchy-gamemode \
           /etc/sddm.conf.d/zz-omarchy-gamemode.conf \
           /etc/omarchy-gamemode.conf \
           /usr/share/wayland-sessions/omarchy-gamemode.desktop \
           /usr/local/share/applications/omarchy-gamemode.desktop \
           /usr/local/bin/omarchy-gamemode
sudo rm -rf "$LIB"
# Don't leave the greeter preselecting a session that no longer exists.
if sudo grep -qs 'omarchy-gamemode.desktop' /var/lib/sddm/state.conf; then
  for s in hyprland-uwsm.desktop hyprland.desktop; do
    if [[ -f /usr/share/wayland-sessions/$s ]]; then
      sudo sed -i "s|^Session=.*omarchy-gamemode.desktop|Session=/usr/share/wayland-sessions/$s|" /var/lib/sddm/state.conf
      break
    fi
  done
fi
echo "Removed Game Mode session, helper, sudoers rule and SDDM override."

if [[ ${1:-} == --packages && -f $here/.installed-packages ]]; then
  mapfile -t pkgs < "$here/.installed-packages"
  sudo pacman -Rns "${pkgs[@]}" && rm -f "$here/.installed-packages"
elif [[ -f $here/.installed-packages ]]; then
  echo "Packages installed by install.sh kept: $(tr '\n' ' ' < "$here/.installed-packages")"
  echo "Run './uninstall.sh --packages' to remove them too."
fi
