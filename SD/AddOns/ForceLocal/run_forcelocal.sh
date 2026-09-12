#!/bin/sh
# Top-level launcher for ForceLocal - copied here by manage.sh ENABLE.
# Called with "kill" by the boot loop on every boot before relaunch.

mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh

appDir="$mmPath/AddOns/ForceLocal"

if [ "$1" == "kill" ]; then
    killall avahi-daemon 2>/dev/null
else
    mkdir -p /var/run/avahi-daemon
    export LD_LIBRARY_PATH="$appDir/lib:$LD_LIBRARY_PATH"
    "$appDir/bin/avahi-daemon" -f "$appDir/avahi-daemon.conf" --no-drop-root --no-chroot >/dev/null 2>&1 &
fi
