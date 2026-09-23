#!/bin/sh
############################################################
# Copy this File to $mmPath/AddOns to Launch Automatically
#
# Delayed start (2026-09-24): drmvncserver opens the display device, and if it
# gets there before MPC does, MPC aborts with "Failed to initialise display
# (another process running?)" and systemd relaunches it in a loop. So this
# waits (in the background, not holding up boot) until MPC is running AND has
# /dev/dri open, then starts VNC. Gives up after 3 minutes.
############################################################

appname=drmvncserver

mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh
export LD_LIBRARY_PATH="$mmPath/AddOns/DrmVncServer:$LD_LIBRARY_PATH"

EVENT() {
    echo "$(sed -n "$(($(cat /proc/bus/input/devices | grep -ni "$1" | cut -d: -f1) + 4))"p /proc/bus/input/devices | grep -Eo 'event[0-9]+')"
}

mpc_has_display() {
    p=$(pidof MPC) || return 1
    for q in $p; do
        ls -l /proc/$q/fd 2>/dev/null | grep -q "/dev/dri/" && return 0
    done
    return 1
}

start_vnc() {
    i=0
    while ! mpc_has_display; do
        i=$((i + 1))
        [ $i -ge 180 ] && { echo "$appname: MPC never opened the display, not starting" >&2; return 1; }
        sleep 1
    done
    sleep 5   # let MPC finish its display setup
    killall "$appname" 2>/dev/null
    card=$(find /sys/devices/platform/display-subsystem/drm -type d -maxdepth 1 -iname "card*" | xargs | cut -d"/" -f7)
    kb=$(EVENT "Amit") #for amits kb input provider!
    ts=$(EVENT "Touchscreen")
    "$appname" -f "/dev/dri/$card" -t "/dev/input/$ts" -k "/dev/input/$kb" -r 90 -F 0 &
}

if [ "$1" == "kill" ]; then
    killall "$appname" 2>/dev/null
else
    start_vnc &
fi
