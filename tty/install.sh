#!/usr/bin/env bash
# Install Game Mode: packages + ~/.local/bin/game-mode + Steam helper shims.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

pkgs=(steam gamescope)
[[ "${1:-}" == "--with-mangohud" ]] && pkgs+=(mangohud lib32-mangohud)

source "$here/../lib/gpu-packages.sh"
add_gpu_packages
missing=()
for p in "${pkgs[@]}"; do pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p"); done
if ((${#missing[@]})); then
  echo "Installing: ${missing[*]}"
  sudo pacman -S --needed "${missing[@]}"
  printf '%s\n' "${missing[@]}" > "$here/.installed-packages"   # what uninstall may remove
fi

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/omarchy-game-mode"
ln -sfn "$here/shims" "$HOME/.local/share/omarchy-game-mode/shims"
ln -sfn "$here/game-mode" "$HOME/.local/bin/game-mode"
echo "Done. Ctrl+Alt+F3, log in, run: game-mode"
