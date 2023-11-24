#!/bin/bash
config="$HOME/.config"
dst="$HOME/src/dotfiles"

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
    rsync -a "$HOME/$item/" "$dst/${item:1}/"
  else
    rsync -a "$HOME/$item" "$dst/${item:1}"
  fi
done

for item in "${files[@]}"
do
  get_file_name $item

  if [[ "$item" == *"toml"* ]]; then
    get_dir_name $item
    rsync -a "$item" "$dst/$file_dir/"
  else
    rsync -a "$item" "$dst/"
  fi
done
