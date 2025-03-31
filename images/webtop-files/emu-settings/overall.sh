#!/bin/bash

# Define the source and destination directories
source_dir="/path/to/source/directory"
destination_dir="/path/to/destination/directory"

# Check if the destination directory exists, if not create it
if [ ! -d "$destination_dir" ]; then
  mkdir -p "$destination_dir"
  echo "Destination directory created."
fi

# List all files in the source directory
files_to_copy=$(find "$source_dir" -type f)

# Loop through each file and copy if it does not exist in the destination directory
for file in $files_to_copy; do
  relative_path="${file#$source_dir/}"
  dest_file="$destination_dir/$relative_path"
  
  # Check if the file already exists in the destination directory
  if [ ! -f "$dest_file" ]; then
    cp "$file" "$dest_file"
    echo "Copied $file to $dest_file"
  else
    echo "$file already exists at $dest_file"
  fi
done