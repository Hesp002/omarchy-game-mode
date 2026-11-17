#!/usr/bin/env bash
# Undo install.sh. Pass --packages to also remove the packages install.sh added.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

rm -f "$HOME/.local/bin/game-mode"
rm -rf "$HOME/.local/share/omarchy-game-mode"
echo "Removed launcher and shims."

if [[ "${1:-}" == "--packages" && -f "$here/.installed-packages" ]]; then
  mapfile -t pkgs < "$here/.installed-packages"
  sudo pacman -Rns "${pkgs[@]}" && rm -f "$here/.installed-packages"
elif [[ -f "$here/.installed-packages" ]]; then
  echo "Packages installed by install.sh kept: $(tr '\n' ' ' < "$here/.installed-packages")"
  echo "Run './uninstall.sh --packages' to remove them too."
fi
