#!/usr/bin/env bash
# Install Game Mode: packages + ~/.local/bin/game-mode + Steam helper shims.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/../lib/common.sh"
source "$here/../lib/gpu-packages.sh"

echo "Installing Game Mode (tty variant)."

step "Detecting graphics hardware"
pkgs=(steam gamescope)
[[ "${1:-}" == "--with-mangohud" ]] && pkgs+=(mangohud lib32-mangohud)
add_gpu_packages

step "Installing packages"
install_missing_packages "$here/.installed-packages"

step "Linking the launcher"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/omarchy-game-mode"
ln -sfn "$here/shims" "$HOME/.local/share/omarchy-game-mode/shims"
info "~/.local/share/omarchy-game-mode/shims → $here/shims"
ln -sfn "$here/game-mode" "$HOME/.local/bin/game-mode"
info "~/.local/bin/game-mode → $here/game-mode"

cat <<DONE

${_b}Game Mode installed.${_r} Ctrl+Alt+F3, log in, run: game-mode

  Tip: start Steam once on the desktop and sign in first. Its first start downloads a few
  hundred MB of updates, which otherwise happens on a mostly black screen in Game Mode.
DONE
