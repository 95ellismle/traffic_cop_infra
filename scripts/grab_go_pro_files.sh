#!/usr/bin/env bash

log_err () {
   echo "ERROR [$(date +'%Y/%m/%d %H:%M:%S'), $?]: $*" >&2
}
log_info () {
   echo "INFO [$(date +'%Y/%m/%d %H:%M:%S'), $?]: $*"
}

log_info "Grabbing GoPro files "

MOUNT_DIR="/home/matt/GoPro"
OUT_DIR="/media/HDD1/GoPro"
TRANS_DIR="/media/HDD1/GoPro/Transfers"

mkdir -p $OUT_DIR
mkdir -p $TRANS_DIR

# Now transfer files from mount point to directory on the HDD
for mnt_filepath in "$MOUNT_DIR/GoPro MTP Client Disk Volume/DCIM/100GOPRO"/GS*.360;
do
    # Get the filename and new filename with date
    log_info "Acting on mount filepath: $mnt_filepath"
    mnt_filename=$(basename "$mnt_filepath")
    log_info "Mount filestem: $mnt_filename, new_filename: $mnt_filename"

    # Copy the file across
		new_filepath="$TRANS_DIR/$mnt_filename"
    if [[ -f "$new_filepath" ]]; then
        log_info "Skipping $new_filepath, as it already exists"
        continue
    fi
    log_info "Copying $mnt_filepath to $new_filepath"
    cp "$mnt_filepath" "$new_filepath"
    log_info "$new_filepath copied"
done

exit 0
