#!/bin/bash

# This requires media to be mounted by the file manager.
# We could just automount the 1T drive with fstab, maybe I'll do that at some point
#
# It would be ideal to have a SAN

BACKUP_DIR=/zfs/media/backuphome
SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

timestamp () {
    echo $(date +%FT%k:%M:%S)
}

log() {
    echo "$(timestamp) -- $1"
}

if [ -d "$BACKUP_DIR" ]; then
    rsync -a --delete-after --exclude-from "$SCRIPT_DIR/../configs/backup-home" "$HOME" "$BACKUP_DIR" && {
        log "Rsync ran successfully"
    } || {
        log "Rsync returned an error code: $?"
    } 
else
    log "Media drive is not connected"
    exit 0
fi
