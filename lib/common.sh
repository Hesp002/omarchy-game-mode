# Sourced by the install/uninstall scripts: progress output and shared helpers.
# shellcheck shell=bash

# Bold "==> step" headers so long runs never look stuck; plain text if not a terminal.
if [[ -t 1 ]]; then _b=$'\033[1m' _y=$'\033[1;33m' _r=$'\033[0m'; else _b='' _y='' _r=''; fi
step() { printf '\n%s==> %s%s\n' "$_b" "$*" "$_r"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '%s    WARNING:%s %s\n' "$_y" "$_r" "$*" >&2; }

# Install whatever in "${pkgs[@]}" is missing, and add it to the list uninstall --packages
# removes (merged with earlier runs, so re-running with another option doesn't lose entries).
install_missing_packages() {
  local list=$1 p missing=()
  for p in "${pkgs[@]}"; do pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p"); done
  if ((${#missing[@]} == 0)); then
    info "All packages already installed."
    return
  fi
  info "Installing: ${missing[*]}"
  info "pacman shows download progress; Steam and the 32-bit drivers are a few hundred MB."
  sudo pacman -S --needed "${missing[@]}"
  { [[ -f $list ]] && cat "$list"; printf '%s\n' "${missing[@]}"; } | sort -u > "$list.tmp"
  mv "$list.tmp" "$list"
}
