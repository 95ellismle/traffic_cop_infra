set -e
if [[ "$(whoami)" != "root" ]]; then
    echo "Please run as root (currently: $(whoami))" >&2;
fi


GIT_ROOT=$()

udev_rule="/etc/udev/rules.d/"
for rule_file in 
if [[ ! -f 
