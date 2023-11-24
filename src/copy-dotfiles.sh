#!/bin/bash
config="$HOME/.config"
dst="$HOME/src/dotfiles"

timestamp () {
    echo $(date +%FT%k:%M:%S)
}

log() {
    echo "$(timestamp) -- $1"
}

hidden_files=(
  ".bashrc"
  ".bashrc.d"
  ".bash_profile"
)

files=(
  "$config/alacritty/alacritty.yml"
  "$config/dunst/dunstrc"
  "$config/helix/config.toml"
  "$config/helix/languages.toml"
  "$config/kitty/kitty.conf"
  "$config/leftwm/config.ron"
)

get_dir_name() {
  local path=$1
  local idx=`expr match "$path" '.*/'`

  # get the previous position and truncate the last /.*
  idx=$((idx-1))
  path=${path:0:idx}

  # get the new last /
  idx=`expr match "$path" '.*/'`
  file_dir="${path:idx}"
}

get_file_name() {
  idx=`expr match "$1" '.*/'`
  file_name="${item:idx}"
}

for item in "${hidden_files[@]}"
do
  # we do the following to remove the . from the filenames
  if [ -d "$HOME/$item" ]; then
    rsync -a "$HOME/$item/" "$dst/${item:1}/" &&
    log "Copied directory $item." ||
    log "Failed to copy $item."
  else
    rsync -a "$HOME/$item" "$dst/${item:1}" &&
    log "Copied file $item." ||
    log "Failed to copy $item."
  fi
done

for item in "${files[@]}"
do
  get_file_name $item
  get_dir_name $item
  rsync -a "$item" "$dst/$file_dir/" &&
    log "Copied file $file_name." ||
    log "Failed to copy $file_name."
done
