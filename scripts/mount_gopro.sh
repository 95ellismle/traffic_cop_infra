#!/usr/bin/env bash
MOUNT_DIR="/home/matt/GoPro"
DEVICE_NAME="GoPro MAX"
VID="2672"
PID="004b"
mkdir -p "$MOUNT_DIR"


# A couple of functions to log to stdout/stderr
log_err () {
   echo "ERROR [$(date +'%Y/%m/%d %H:%M:%S'), $?]: $*" >&2
}
log_info () {
   echo "INFO [$(date +'%Y/%m/%d %H:%M:%S'), $?]: $*"
}

log_info "Starting GoPro mount"

# unmount if directory didn't properly unmount last time
if [[ "$(ls GoPro 2>&1)" == *"Input/output error" ]]; then
    umount $MOUNT_DIR
fi

# Check the device is definitely plugged in & get device details to mount
check=$(jmtpfs --listDevices | grep "$VID" | grep "$PID")
if [[ -z $check ]]; then
    log_info "Can't find device -sleeping for 5 seconds and trying again"
    exit 1
else
    details=$(lsusb -v | grep "$DEVICE_NAME" | grep "Bus.*?:" -Poh)
    bus_num=$(echo $details | cut -d' ' -f 2)
    device_num=$(echo $details | cut -d' ' -f 4 | cut -d':' -f 1)
    log_info "Found device, ID='$device_num', BusNum=$bus_num"
fi


# Attempt the mounting now
if (( $(ls $MOUNT_DIR | wc -l ) == 0 )); then
    log_info "Attempting to mount device (bus=$bus_num,device=$device_num) at: '$MOUNT_DIR'"
    /usr/bin/jmtpfs "$MOUNT_DIR" -device=$bus_num,$device_num

    # Check the mount is mounted
    if (( $(ls $MOUNT_DIR | wc -l ) == 0 )); then
        log_err "Something went wrong with the mounting of the device..."
        exit 1
    fi
else
    log_info "Drive already mounted, skipping"
fi

# Now grab the required files
log_info "GoPro mounted at: '$MOUNT_DIR'"
/home/matt/Projects/GoProScraping/scripts/grab_go_pro_files.sh
