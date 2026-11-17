#!/usr/bin/env bash
# Undo install.sh. Pass --packages to also remove the packages install.sh added.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/../lib/common.sh"

echo "Uninstalling Game Mode (tty variant)."

step "Removing the launcher and SteamOS helper stand-ins"
rm -f "$HOME/.local/bin/game-mode"
rm -rf "$HOME/.local/share/omarchy-game-mode"
info "Removed ~/.local/bin/game-mode and ~/.local/share/omarchy-game-mode."

if [[ "${1:-}" == "--packages" && -f "$here/.installed-packages" ]]; then
  step "Removing packages the installer added"
  mapfile -t pkgs < "$here/.installed-packages"
  sudo pacman -Rns "${pkgs[@]}" && rm -f "$here/.installed-packages"
elif [[ -f "$here/.installed-packages" ]]; then
  step "Keeping packages"
  info "Kept: $(tr '\n' ' ' < "$here/.installed-packages")"
  info "Run uninstall with --packages to remove them too."
fi
