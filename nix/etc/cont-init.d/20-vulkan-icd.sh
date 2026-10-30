#!/usr/bin/env bash

set -e

# Mesa's Vulkan ICD manifests are baked into /etc/vulkan/icd.d (see the
# vulkan-icd-etc derivation in gowbase.nix). This generation of the Vulkan
# loader does not search /etc/vulkan/icd.d: it searches XDG locations
# first, starting at $HOME/.config/vulkan/icd.d. Symlink the manifests
# there so drivers are discovered without VK_ICD_FILENAMES.
if [ -d /etc/vulkan/icd.d ] && [ ! -e "${HOME}/.config/vulkan/icd.d" ]; then
    mkdir -p "${HOME}/.config/vulkan"
    ln -s /etc/vulkan/icd.d "${HOME}/.config/vulkan/icd.d"
    gow_log "Vulkan ICDs available at ${HOME}/.config/vulkan/icd.d"
fi

gow_log "DONE"
