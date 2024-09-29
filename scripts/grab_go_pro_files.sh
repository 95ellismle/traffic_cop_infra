#!/usr/bin/env bash

LOG_FILE="/home/matt/log/grab_go_pro_files_$(date +%Y%m%d).log"

log_err () {
   echo "ERROR [$(date +'%Y/%m/%d %H:%M:%S'), $?]: $*" >> $LOG_FILE
}
log_info () {
   echo "INFO [$(date +'%Y/%m/%d %H:%M:%S'), $?]: $*" >> $LOG_FILE
}

log_info "Starting GoPro file transfer"

GOPRO_MOUNT_DIR="/media/GoPro"
GOPRO_OUT_DIR="/media/HDD1/GoPro"
GOPRO_TRANS_DIR="/media/HDD1/GoPro/Transfers"


# Must be root for mtp to detect anything
if [[ $EUID -ne 0 ]]; then
   log_err "This script must be run as root"
   exit 1
fi


# Check the GoPro out dir exists
if [[ ! -d "$GOPRO_OUT_DIR" ]]; then
   log_err "GoPro output directory not found at: '$GOPRO_OUT_DIR'"
   exit 1
fi
if [[ ! -d "$GOPRO_TRANS_DIR" ]]; then
   mkdir "$GOPRO_TRANS_DIR"
   log_info "Created directory at: $GOPRO_TRANS_DIR"
fi


# Get Device ID and make sure the GoPro is connected -try 5 times. If not successful then fall over afterwards.
for i in $(seq 5);
do
    check=$(jmtpfs --listDevices 2>&1 | grep "VID=2672" | grep "PID=004b")
    if [[ -z $check ]]; then
        log_info "Can't find GoPro device -sleeping for 5 seconds and trying again"
        continue
    else
        details=$(lsusb -v | grep "GoPro MAX" | grep "Bus.*?:" -Poh)
        bus_num=$(echo $details | cut -d' ' -f 2)
        device_num=$(echo $details | cut -d' ' -f 4 | cut -d':' -f 1)
        log_info "Found device, ID='$device_num', BusNum=$bus_num"
        break
    fi
    sleep 5
done
if [[ -z $device_num ]]; then
    log_err "Couldn't find the GoPro plugged in -something went wrong."
fi

# Now mount the MTP device
sleep 1
if [[ ! -d $GOPRO_MOUNT_DIR ]]; then
    log_info "Creating dir at: '$GOPRO_MOUNT_DIR'"
    mkdir $GOPRO_MOUNT_DIR
fi
if (( $(ls /media/GoPro | wc -l ) == 0 )); then
    log_info "Attempting device mounting"
    jmtpfs /media/GoPro/ -device=$bus_num,$device_num 2> /dev/null
else
    log_info "Drive already mounted, skipping"
fi


# Now transfer files from mount point to directory on the HDD
for mnt_filepath in "$GOPRO_MOUNT_DIR/GoPro MTP Client Disk Volume/DCIM/100GOPRO"/GS*.360;
do
    # Get the filename and new filename with date
    log_info "Acting on mount filepath: $mnt_filepath"
    mnt_filename=$(basename "$mnt_filepath")
    log_info "Mount filestem: $mnt_filename, new_filename: $mnt_filename"

    # Copy the file across
		new_filepath="$GOPRO_TRANS_DIR/$mnt_filename"
    if [[ -f "$new_filepath" ]]; then
        log_info "Skipping $new_filepath, as it already exists"
        continue
    fi
    log_info "Copying $mnt_filepath to $new_filepath"
    cp "$mnt_filepath" "$new_filepath"
    log_info "$new_filepath copied"
done
