#!/usr/bin/env bash

LOG_FILE="/home/matt/log/grab_go_pro_files_$(date +%Y%m%d).log"

log_err () {
   echo "ERROR [$(date +'%Y/%m/%d %H:%M:%S'), $?]: $*" >> $LOG_FILE
}
log_info () {
   echo "INFO [$(date +'%Y/%m/%d %H:%M:%S'), $?]: $*" >> $LOG_FILE
}

log_info "Starting GoPro file transfer"

GOPRO_OUT_DIR="/media/HDD2/GoPro"
GOPRO_TRANS_DIR="/media/HDD2/GoPro/Transfers"


# Must be root for mtp to detect anything
if [[ $EUID -ne 0 ]]; then
   log_err "This script must be run as root"
   exit 1
fi

# Check the GoPro is plugged in
for i in 1 2 3;
do
	check=$((mtp-detect 2>/dev/null) | grep -c "GoPro")
	log_info "Checking mtp-detect for GoPro"
	if (( check < 1 )); then
	   if $(( i == 3 )); then
			 log_err "Couldn't detect GoPro -exitting."
			 exit 1
		 fi
	else
		 log_info "GoPro detected"
     break
	fi
  sleep 2
done

# Check the GoPro out dir exists
if [[ ! -d "$GOPRO_OUT_DIR" ]]; then
   log_err "GoPro output directory not found at: '$GOPRO_OUT_DIR'"
   exit 1
fi
if [[ ! -d "GOPRO_TRANS_DIR" ]]; then
   mkdir -p "$GOPRO_TRANS_DIR"
   log_info "Created directory at: $GOPRO_TRANS_DIR"
fi

# Now grab the files
sleep 1
device_id=$(mtp-detect 2>&1 | grep "Device [0-9]*" -oh | grep "[0-9]*" -oh)
log_info "Device: $device_id"

sleep 1  # mtp needs to sleep for a bit between calls
files="$(/usr/bin/mtp-files | grep "GS.*\.360" -B1 -A3)"
files=$(/usr/bin/python3 -c "print('''$files'''.replace('\n', ''))")

IFS='--'
for file in $files;
do
   filename=$(echo $file | grep "GS.*\.360" -oh)
	 if [[ -z $filename ]]; then continue; fi
	 file_id=$(echo $file | grep "File ID: [0-9]+" -Poh | grep "[0-9]+" -Poh)
	 log_info "Filename: $filename"
	 log_info "FileID: $file_id"

	 filepath="$GOPRO_TRANS_DIR/$filename"
	 filestem="$(echo $filename | cut -d'.' -f1)"

	 # Transfer the file
   if [[ ! -f $filepath ]] && [[ ! $(ls $GOPRO_TRANS_DIR/$filestem*.360 2>/dev/null) ]]; then
			 sleep 1
		   mtp-getfile $device_id $file_id $filepath
   else
		   log_info "Already processed: $filepath"
   fi

	 # Add the created date
	 if [[ -f "$filepath" ]]; then
			 create_date=$(exiftool -s -time:CreateDate $filepath | awk '{print $3"_"$4}' | sed s/":"/""/g)
			 new_filepath="$GOPRO_TRANS_DIR/${filestem}_${create_date}.360"
       if [[ ! -f "$new_filepath" ]]; then
				 log_info "File moved from $filepath -> $new_filepath"
				 mv $filepath $new_filepath
       else
				 log_err "Not moving $filepath, $new_filepath already exists"
       fi
   fi
done

