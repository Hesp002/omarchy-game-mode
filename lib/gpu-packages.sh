# Sourced by the installers (after common.sh). Appends Vulkan userspace driver packages (64- and 32-bit)
# for every GPU present to the caller's `pkgs` array — hybrid laptops get both.
# Display (0300) + 3D (0302) controllers; vendor IDs: 1002 AMD, 8086 Intel, 10de NVIDIA.
# shellcheck shell=bash
add_gpu_packages() {
  local gpus v utils
  gpus=$(lspci -n | awk '$2 ~ /^030[02]:/ {print $3}' | cut -d: -f1 | sort -u)
  [[ -z $gpus ]] && { warn "No GPU detected via lspci; skipping driver packages."; return; }
  for v in $gpus; do
    case $v in
      1002) info "GPU: AMD";   pkgs+=(mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon) ;;
      8086) info "GPU: Intel"; pkgs+=(mesa lib32-mesa vulkan-intel lib32-vulkan-intel) ;;
      10de) info "GPU: NVIDIA"
        # Omarchy installs the kernel driver; only add the matching 32-bit userspace.
        # Handles legacy branches too (nvidia-580xx-utils → lib32-nvidia-580xx-utils).
        utils=$(pacman -Qq 2>/dev/null | grep -xE 'nvidia(-[0-9]+xx)?-utils' | head -1 || true)
        if [[ -n $utils ]]; then
          pkgs+=("lib32-$utils")
          NVIDIA_PRESENT=1
        else
          warn "No nvidia-utils installed; set up the NVIDIA driver first (Omarchy normally does)."
        fi ;;
      *) warn "Unknown GPU vendor $v; skipping its driver packages." ;;
    esac
  done
}
