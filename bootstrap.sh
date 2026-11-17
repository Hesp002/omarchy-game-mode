#!/usr/bin/env bash
# One-line installer for omarchy-game-mode.
#
#   curl -fsSL https://raw.githubusercontent.com/Hesp002/omarchy-game-mode/main/bootstrap.sh | bash -s -- [install|uninstall] [session|tty] [options]
#
# Examples:
#   ... | bash                                        # install the full session variant
#   ... | bash -s -- install session --boot-to desktop --desktop-login greeter
#   ... | bash -s -- install tty --with-mangohud
#   ... | bash -s -- uninstall session --packages
#
# Downloads the repo tarball to ~/.local/share/omarchy-game-mode-src (kept: the tty variant
# links into it, and uninstall reads the package list recorded there), then runs the
# variant's install.sh / uninstall.sh. Set OGM_REF=<tag|commit> to pin a version.

# Everything is inside main(), called on the last line, so bash has read the whole script
# before anything runs and the installers can safely read prompts from the terminal.
main() {
  set -euo pipefail
  local repo=Hesp002/omarchy-game-mode
  local ref=${OGM_REF:-main}
  local dest=${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-game-mode-src
  local action=install variant=session

  case ${1:-} in install|uninstall) action=$1; shift ;; esac
  case ${1:-} in session|tty)       variant=$1; shift ;; esac

  [[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root (sudo is used where needed)." >&2; exit 1; }
  { : </dev/tty; } 2>/dev/null || { echo "Needs an interactive terminal for sudo/pacman prompts." >&2; exit 1; }

  if [[ $action == uninstall ]]; then
    [[ -x $dest/$variant/uninstall.sh ]] || { echo "Nothing to uninstall: $dest/$variant not found." >&2; exit 1; }
    echo "Running $variant/uninstall.sh $*"
    "$dest/$variant/uninstall.sh" "$@" </dev/tty
    # Remove the source only when nothing still depends on it.
    if [[ -L $HOME/.local/bin/game-mode || -f /etc/omarchy-gamemode.conf ]] ||
       compgen -G "$dest/*/.installed-packages" >/dev/null; then
      echo "Source kept in $dest (a variant or its package list is still installed)."
    else
      rm -rf "$dest"
      echo "Removed $dest."
    fi
    return
  fi

  echo "Downloading $repo@$ref ..."
  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "https://codeload.github.com/$repo/tar.gz/$ref" | tar -xz -C "$tmp" --strip-components=1
  echo "Unpacking to $dest"

  # Carry over package lists from a previous install so uninstall --packages still works.
  local v
  for v in session tty; do
    [[ -f $dest/$v/.installed-packages ]] && cp "$dest/$v/.installed-packages" "$tmp/$v/"
  done
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  mv "$tmp" "$dest"
  trap - EXIT

  echo "Running $variant/install.sh $*"
  "$dest/$variant/install.sh" "$@" </dev/tty
}

main "$@"
