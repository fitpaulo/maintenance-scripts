#!/bin/bash

# Okay, the goal is to grab the recently dowloaded
# altppr file in ~/Downloads and move it to the
# /home/share/cave-story dir
# delete the current cave-story-msu.sfc file
# rename the alttpr file to cave-story...

DOWNLOADS_DIR="$HOME/Downloads"
SAGA_DIR="/home/share/SaGa Frontier"
NEW_NAME="saga.sfc"


for file in "$DOWNLOADS_DIR"/*; do
  if [ -f "$file" ]; then
    if [[ "$file" =~ alttpr.*\.sfc ]]; then
      f="${file##*/}"
      echo "Found $f"
      cd "$DOWNLOADS_DIR"
      mv "$f" "$SAGA_DIR/$NEW_NAME"
    fi
  fi
done
