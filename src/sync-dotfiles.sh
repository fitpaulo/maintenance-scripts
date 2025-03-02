#!/bin/bash

script_config_dir="$HOME/src/maintenance-scripts/configs"
# file_extensions="$script_config_dir/config-file-extensions"
# subdirs="$script_config_dir/config-subdirs"
patterns="$script_config_dir/dotfile_patterns"
input="$HOME/.config/"
output="$HOME/src/dotfiles"
bash_scripts_dir="$HOME/.bashrc.d"

hidden_files=(".bashrc" ".bash_profile" ".profile")

# Default rsync options
RSYNC_OPTS="-av"

# Parse long and short options
TEMP=$(getopt -o vd --long verbose,dry-run -n "$0" -- "$@")
[ $? -ne 0 ] && { echo "Usage: $0 [-v|--verbose] [-d|--dry-run]"; exit 1; }
eval set -- "$TEMP"

while true; do
  case "$1" in
    -v|--verbose) RSYNC_OPTS="-avP"; shift ;;
    -d|--dry-run) RSYNC_OPTS="$RSYNC_OPTS --dry-run"; shift ;;
    --) shift; break ;;
    *) echo "Usage: $0 [-v|--verbose] [-d|--dry-run]"; exit 1 ;;
  esac
done

# Check dirs
[ -d "$input" ] || { echo "Error: $input not found"; exit 1; }
[ -d "$output" ] || mkdir -p "$output" || { echo "Error: Can’t create $output"; exit 1; }

# Hidden files
# for item in "${hidden_files[@]}"; do
#   rsync $RSYNC_OPTS "$HOME/$item" "$output/${item:1}" --delete-after
# done

# Config sync with optional includes
# [ -f "$file_extensions" ] && ext_opt="--include-from=$file_extensions" || ext_opt=""
# [ -f "$subdirs" ] && subdir_opt="--include-from=$subdirs" || subdir_opt=""
[ -f "$patterns" ] && patterns_opt="--include-from=$patterns" || patterns_opt=""
rsync $RSYNC_OPTS $patterns_opt --exclude='*' --copy-links --delete-after "$input" "$output"

# Bash scripts
# [ -d "$bash_scripts_dir" ] && rsync $RSYNC_OPTS --include="*.sh" --exclude='*' "$bash_scripts_dir/" "$output" --delete-after
