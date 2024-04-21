set -e
if [[ "$(whoami)" != "root" ]]; then
    echo "Please run as root (currently: $(whoami))" >&2;
fi


GIT_ROOT=$(git rev-parse --show-toplevel)
MY_UDEV_DIR="$GIT_ROOT/etc/udev"
UDEV_SYS_DIR="/etc/udev/rules.d"
LOG_DIR="/home/matt/log"

mkdir -p $LOG_DIR


echo "Copying UDEV rules"
for rule_file in $MY_UDEV_DIR/*.rules; do
  rule_filename=$(basename $rule_file)
	new_filepath="$UDEV_SYS_DIR/$rule_filename"
	#if [[ ! -f $new_filepath ]]; then
		echo "  Copying: $rule_file -> $new_filepath"
		cp $rule_file $new_filepath
		chmod 644 $new_filepath
	#fi
done
udevadm control --reload
udevadm trigger
echo "Finished copying UDEV rules"


echo "Copying fstab setup"
added_setup_block=0
while read line; 
do 
	  set +e
		line_exists=$(/bin/egrep -c "$line" /etc/fstab)
	  set -e
    if (( line_exists == 0 )); then
       if (( added_setup_block == 0 )); then
					 echo "" >> /etc/fstab
           echo "#### Added by setup script at $(date +"%Y/%m/%d %H:%M:%S")" >> /etc/fstab
					 added_setup_block=1
       fi
	     echo $line >> /etc/fstab
    fi
done < etc/fstab
if (( added_setup_block == 1 )); then
 	 echo "##############" >> /etc/fstab
fi
echo "Finished copying fstab setup"
