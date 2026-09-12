#!/bin/sh
# ForceAudioIn AddOn Manager (MockbaMod convention).
#   sh manage.sh ENABLE | DISABLE | UNINSTALL
#
# Mixes a synthesized signal (injectTone, a stand-in for a real MIDI-generator
# renderer) into what MPC reads from its capture device, via LD_PRELOAD
# symbol-interposition of snd_pcm_readi - the inverse of the ForceLinkAudio
# addon's snd_pcm_writei tap. Restarting the `acvs` service (confirmed via
# `systemctl list-units` to be the actual "InMusic MPC Application" service -
# NOT a service literally named inmusic-mpc) is required for a changed
# LD_PRELOAD to take effect, since it's read once at process start.

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

STOP() {
    for p in $(ps 2>/dev/null | grep "[i]njectTone" | awk '{print $1}'); do
        kill -9 $p 2>/dev/null
    done
    if [ -f "$mmLD_PRELOAD_VAR" ]; then
        cat "$mmLD_PRELOAD_VAR" | tr " " "\n" | grep -v forceAudioIn | tr "\n" " " > /tmp/.p
        mv /tmp/.p "$mmLD_PRELOAD_VAR"
    fi
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
    echo "$appTitle enabled. Restarting the Force app."
    systemctl restart acvs
    exit 0
fi

echo "Usage: sh manage.sh ENABLE | DISABLE | UNINSTALL"
echo
echo "Status:"
[ -f "$runScript" ] && echo "  autostart: ENABLED" || echo "  autostart: disabled"
ps 2>/dev/null | grep -q "[i]njectTone" && echo "  injector: RUNNING" || echo "  injector: stopped"
echo "  logs: /tmp/forceAudioIn.log (shim) and /tmp/injectTone.log (generator)"
