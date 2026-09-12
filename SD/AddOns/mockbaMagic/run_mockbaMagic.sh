#!/bin/sh

# Set up the environment
mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh

LD_LIB=/media/662522/AddOns/mockbaMagic/mockbaMagic.so

SETLIBS() {
    # LOCK ADDED 2026-09-13: this read-modify-write of $mmLD_PRELOAD_VAR
    # raced with MidiLoop's own (and any other addon's) identical unlocked
    # read-modify-write, since boot.sh backgrounds every top-level addon
    # script concurrently. Confirmed live as the cause of intermittent
    # dead-pads/dead-WiFi across reboots (whichever write landed last won,
    # silently dropping another script's entry). mkdir is atomic even on
    # this busybox userland; bounded retry, fails OPEN (proceeds anyway)
    # rather than risk hanging boot forever on a stale lock.
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
            #always prepend to start
            echo "$LD_LIB $FC " >"$mmLD_PRELOAD_VAR"
        fi

    else

        echo "$LD_LIB" >"$mmLD_PRELOAD_VAR"
    fi

    rmdir /dev/shm/.LD_PRELOAD.lock 2>/dev/null
}

if test "$1" != "kill"; then
#    SETLIBS
/media/662522/AddOns/mockbaMagic/livePatcher.sh &
   sleep 1
fi
