#!/usr/bin/env bash

# Seed directory. The image sets HOME=/home/retro; default it here if unset so
# the seeder still lands in the right place when invoked directly.
HOME="${HOME:-/home/retro}"

# Define the source and destination directories.
# Source: the bundled "canned" defaults installed to /etc/cumulus-emu by gowbase.nix.
# Dest:   the XDG locations the emulators actually use in the live image:
#          $HOME/.config          (XDG config: flycast, rpcs3, RMG, dolphin-emu,
#                                  PCSX2, eden, xenia_edge.conf, ...)
#          $HOME/.local/share     (XDG data:   Xenia, eden keys, xemu, duckstation, ...)
source_dir1="${CUMULUS_SRC_CONFIG:-/etc/cumulus-emu/config}"
source_dir2="${CUMULUS_SRC_LOCAL:-/etc/cumulus-emu/local}"
destination_dir1="${HOME}/.config"
destination_dir2="${HOME}/.local/share"

# Copy the project.godot file to the working directory.
# Cartouche is a Godot release export; Godot looks for project.godot in the
# current directory before falling back to the binary's directory. Without it,
# the main scene resource is null and cartouche exits immediately.
if [ -f /etc/cumulus-emu/config/cartouche/project.godot ]; then
    if [ ! -f "${HOME}/project.godot" ]; then
        cp /etc/cumulus-emu/config/cartouche/project.godot "${HOME}/project.godot"
        echo "Copied project.godot to ${HOME}/project.godot"
    fi
fi

# Function to copy files from a source directory to a destination directory
copy_files() {
    local source_dir=$1
    local destination_dir=$2

    # Check if the destination directory exists, if not create it
    if [ ! -d "$destination_dir" ]; then
        mkdir -p "$destination_dir"
        echo "Destination directory created: $destination_dir"
    fi

    # List all files in the source directory. -L: the image layer ships these
    # trees as symlinks into /nix/store, and plain `find -type f` never matches
    # symlinks — without -L the loop iterates zero times and nothing is seeded.
    files_to_copy=$(find -L "$source_dir" -type f)

  # Loop through each file and copy if it does not exist in the destination directory
  for file in $files_to_copy; do
    relative_path="${file#$source_dir/}"
    dest_file="$destination_dir/$relative_path"
    
    # Create necessary directories in the destination path if they don't exist
    mkdir -p "$(dirname "$dest_file")"

    # Check if the file already exists in the destination directory
    if [ ! -f "$dest_file" ]; then
      cp "$file" "$dest_file"
      echo "Copied $file to $dest_file"
    else
      echo "$file already exists at $dest_file"
    fi
  done
}

# Call the function for each pair of source and destination trees
copy_files "$source_dir1" "$destination_dir1"
copy_files "$source_dir2" "$destination_dir2"

# Hand ownership back to the emulator user. The seeder runs as root during
# container init; root-owned files (644) and directories (755) in these
# trees block the emulators from writing configs/caches at runtime (xenia
# crashed on a Permission denied creating its cache dirs). chown -R every
# boot also repairs any tree already contaminated by an earlier boot.
# Nonfatal: a missing user (weird boot) must never block container start.
chown -R retro:retro "$destination_dir1" "$destination_dir2" 2>/dev/null \
    || echo "[overall.sh] warning: could not chown seeded trees to retro"