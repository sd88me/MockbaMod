#!/bin/sh
############################################################
# ForceAudioIn — autostart hook.
# Copy this file into the AddOns FOLDER ROOT to enable.
# MockbaMod's boot.sh runs every *.sh in AddOns/ at startup.
#
# ARMS THE TAP ONLY. Does not start any producer (not injectTone, not any
# voice-host addon's binary) - see manage.sh's header comment for why:
# every live test of "acvs restart while a voice is attached" has failed,
# while "forceAudioIn.so armed with zero voices" has survived every
# repeated-restart test run against it, including a real physical reboot.
# So this script's whole job at boot is: arm the tap, attach nothing.
#
# Voices attach later, entirely through their own nodeServer Modules-page
# toggle (which spawns a process directly - no LD_PRELOAD, no acvs
# restart). forceAudioIn.so's own background thread lazily re-attaches
# any voice ring that appears (or reappears, e.g. after a stop/restart)
# within ~2s, with no restart needed. This addon being the ONLY one that
# ever touches $mmLD_PRELOAD_VAR's forceAudioIn entry is what makes that
# safe - if two addons both armed the tap, they'd race on this same file
# exactly like mockbaMagic/MidiLoop once did (see README.md).
############################################################

mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh
APPDIR="$mmPath/AddOns/ForceAudioIn"
LIB="$APPDIR/forceAudioIn.so"

# ── Locking around $mmLD_PRELOAD_VAR ────────────────────────
# CONFIRMED live (2026-09-13): mockbaMagic's and MidiLoop's own run_*.sh
# scripts both read this same file, check their library isn't already in
# it, and write the whole file back - with NO locking at all - while
# boot.sh backgrounds every top-level addon script concurrently. That's a
# real, observed lost-update race: whichever write lands last wins,
# silently dropping another script's entry. This can't fix their side of
# it, only make ours safe. mkdir is atomic even on busybox; the retry is
# bounded and fails OPEN (proceeds unlocked) rather than risk hanging boot
# forever on a stale lock from a crashed process.
PRELOAD_LOCK="/dev/shm/.LD_PRELOAD.lock"
lock_preload() {
    i=0
    while ! mkdir "$PRELOAD_LOCK" 2>/dev/null; do
        i=$((i + 1))
        [ $i -ge 50 ] && return 1   # ~5s of retries, then fail open
        sleep 0.1
    done
    return 0
}
unlock_preload() { rmdir "$PRELOAD_LOCK" 2>/dev/null; }

# boot.sh calls addon scripts with "kill" on shutdown/restart - full teardown.
if [ "$1" = "kill" ]; then
    for p in $(ps 2>/dev/null | grep "[i]njectTone" | awk '{print $1}'); do
        kill -9 $p 2>/dev/null
    done
    lock_preload
    if [ -f "$mmLD_PRELOAD_VAR" ]; then
        cat "$mmLD_PRELOAD_VAR" | tr " " "\n" | grep -v forceAudioIn | tr "\n" " " > /tmp/.p.$$
        mv /tmp/.p.$$ "$mmLD_PRELOAD_VAR"
    fi
    unlock_preload
    exit 0
fi

# ── ARM THE TAP - nothing else ─────────────────────────────
lock_preload
if [ -f "$mmLD_PRELOAD_VAR" ]; then
    FC=$(cat "$mmLD_PRELOAD_VAR" | tr " " "\n" | grep -v forceAudioIn | tr "\n" " ")
    echo "$LIB $FC" > "$mmLD_PRELOAD_VAR"
else
    echo "$LIB" > "$mmLD_PRELOAD_VAR"
fi
unlock_preload
