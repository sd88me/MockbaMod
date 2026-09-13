#!/bin/sh
# ForceAudioIn AddOn Manager (MockbaMod convention).
#   sh manage.sh ENABLE | DISABLE | UNINSTALL
#
# This is the SHARED audio-injection tap: it arms forceAudioIn.so
# (LD_PRELOAD'd into MPC, symbol-interposing snd_pcm_readi - not raw
# address patching, so no firmware-version dependency) with ZERO voices
# ever attached at boot. It does not start any producer itself.
#
# Any number of separate voice-host addons (force-maze's ForceMazeVoice,
# injectTone below, future ones) attach to it later, on demand, via their
# own nodeServer Modules-page toggle - never at boot, never via this
# addon's own scripts. forceAudioIn.so mixes every attached voice
# together (up to 4 simultaneous slots) and picks up a voice started
# after boot within ~2s (lazy re-attach), no acvs restart needed.
#
# Restarting `acvs` (confirmed via `systemctl list-units` to be the real
# "InMusic MPC Application" service - NOT literally named "inmusic-mpc")
# is required for a changed LD_PRELOAD to take effect, since it's read
# once at process start. Live testing found that restarting acvs while
# ANY voice is attached reliably kills pads/buttons - see README.md.
# Enabling/disabling THIS addon never attaches a voice, so it's always
# safe to do.

appname=ForceAudioIn
appTitle="Force Audio In"
appDir=ForceAudioIn

mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh

runDir="$mmPath/AddOns"
installroot="$runDir/$appDir"
runScript="$runDir/run_$appname.sh"
mode=$1

echo "
***********************************************************
*   $appTitle AddOn Manager for MockbaMod
***********************************************************
"

# See run_ForceAudioIn.sh for why this lock exists: mockbaMagic's and
# MidiLoop's own scripts read-modify-write the shared LD_PRELOAD file with
# no locking, concurrently at boot - a confirmed lost-update race. This
# can't fix their side of it, only make ours safe.
PRELOAD_LOCK="/dev/shm/.LD_PRELOAD.lock"
lock_preload() {
    i=0
    while ! mkdir "$PRELOAD_LOCK" 2>/dev/null; do
        i=$((i + 1))
        [ $i -ge 50 ] && return 1
        sleep 0.1
    done
    return 0
}
unlock_preload() { rmdir "$PRELOAD_LOCK" 2>/dev/null; }

STOP() {
    for p in $(ps 2>/dev/null | grep "[i]njectTone" | awk '{print $1}'); do
        kill -9 $p 2>/dev/null
    done
    lock_preload
    if [ -f "$mmLD_PRELOAD_VAR" ]; then
        cat "$mmLD_PRELOAD_VAR" | tr " " "\n" | grep -v forceAudioIn | tr "\n" " " > /tmp/.p.$$
        mv /tmp/.p.$$ "$mmLD_PRELOAD_VAR"
    fi
    unlock_preload
}

if [ "$mode" = "UNINSTALL" ]; then
    STOP
    rm -f "$runScript" 2>/dev/null
    rm -rf "$installroot" 2>/dev/null
    echo "<<<< $appTitle uninstalled. Restarting the Force app."
    systemctl restart acvs
    exit 0
fi

if [ "$mode" = "DISABLE" ]; then
    STOP
    rm -f "$runScript" 2>/dev/null
    echo "$appTitle disabled. Restarting the Force app."
    systemctl restart acvs
    exit 0
fi

if [ "$mode" = "ENABLE" ]; then
    cp "$installroot/run_$appname.sh" "$runScript" 2>/dev/null
    chmod 755 "$runScript" 2>/dev/null
    echo "$appTitle enabled (tap armed at boot, zero voices). Restarting the Force app."
    systemctl restart acvs
    exit 0
fi

echo "Usage: sh manage.sh ENABLE | DISABLE | UNINSTALL"
echo
echo "Status:"
[ -f "$runScript" ] && echo "  autostart: ENABLED (tap arms at boot, zero voices)" || echo "  autostart: disabled"
ps 2>/dev/null | grep -q "[i]njectTone" && echo "  injectTone (test producer): RUNNING" || echo "  injectTone (test producer): stopped"
echo "  start/stop any voice (injectTone, force-maze's maze_host, ...) from the"
echo "  nodeServer Modules page (/moduler) instead - never from this script."
echo "  logs: /tmp/forceAudioIn.log (the shared tap)"
