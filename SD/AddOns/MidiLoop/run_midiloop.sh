#!/bin/sh

# Set up the environment
mmPath=`cat /dev/shm/.mmPath`
. $mmPath/MockbaMod/env.sh

LD_LIB="$mmPath/AddOns/MidiLoop/tkgl_anyctrl_lt.so"

SETLIBS() {

[ -f "$mmANYCTL_VAR" ] || echo "Mockba Automation Out" > "$mmANYCTL_VAR"

# LOCK ADDED 2026-09-13: this read-modify-write of $mmLD_PRELOAD_VAR raced
# with mockbaMagic's own (and any other addon's) identical unlocked
# read-modify-write, since boot.sh backgrounds every top-level addon script
# concurrently. Confirmed live as the cause of intermittent dead-pads/dead-
# WiFi across reboots (whichever write landed last won, silently dropping
# another script's entry). mkdir is atomic even on this busybox userland;
# bounded retry, fails OPEN (proceeds anyway) rather than risk hanging boot
# forever on a stale lock.
i=0
while ! mkdir /dev/shm/.LD_PRELOAD.lock 2>/dev/null; do
    i=$((i + 1))
    [ $i -ge 50 ] && break
    sleep 0.1
done

if [ -f "$mmLD_PRELOAD_VAR" ]; then
    #if exists check if its already loaded, otherwise append to end.

    FC=$(cat "$mmLD_PRELOAD_VAR")

    if [[ "$FC" != *"$LD_LIB"* ]]; then
        #always append to end
        echo "$FC $LD_LIB" > "$mmLD_PRELOAD_VAR"
    fi

else

    echo "$LD_LIB" > "$mmLD_PRELOAD_VAR"
fi

rmdir /dev/shm/.LD_PRELOAD.lock 2>/dev/null

}

if test "$1" == "kill"; then
    killall midiloop
else
    SETLIBS
    $mmPath/AddOns/MidiLoop/midiloop 2>/dev/null &
    echo
fi
