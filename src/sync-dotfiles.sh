#!/bin/bash

script_config_dir="$HOME/src/scripts/configs"
file_extensions="$script_config_dir/config-file-extensions"
subdirs="$script_config_dir/config-subdirs"
bash="$script_config_dir/bash"

input="$HOME"
output="$HOME/src/dotfiles"

rsync -aP --include-from="$file_extensions" --include-from="$subdirs" --exclude='*' "$input" "$output"
rsync -aP --include-from="$bash" --exclude='*' "$HOME" "$output"
rsync -aP --include="*.sh" --exclude='*' "$HOME/.bashrc.d/" "$output"
