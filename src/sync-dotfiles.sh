#!/bin/bash

script_config_dir="$HOME/src/maintenance-scripts/configs"
file_extensions="$script_config_dir/config-file-extensions"
subdirs="$script_config_dir/config-subdirs"
bash="$script_config_dir/bash"

input="$HOME/.config/"
output="$HOME/src/dotfiles"

hidden_files=(
  ".bashrc"
  ".bash_profile"
  ".profile"
)

for item in "${hidden_files[@]}"
do
  # we do the following to remove the . from the filenames
  rsync -aP "$HOME/$item" "$output/${item:1}" --delete-after
done

rsync -aP --include-from="$file_extensions" --include-from="$subdirs" --exclude='*' --copy-links --delete-after "$input" "$output"
rsync -aP --include="*.sh" --exclude='*' "$HOME/.bashrc.d/" "$output" --delete-after
