#!/bin/sh
############################################################
# ForceAudioIn — autostart hook.
# Copy this file into the AddOns FOLDER ROOT to enable.
# MockbaMod's boot.sh runs every *.sh in AddOns/ at startup.
#
# Mirrors ForceLinkAudio's boot-race handling: boot.sh backgrounds addon
# launcher scripts before it exports LD_PRELOAD a few lines later, so this
# arms the tap first, before anything else.
############################################################

mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh
APPDIR="$mmPath/AddOns/ForceAudioIn"
LIB="$APPDIR/forceAudioIn.so"

# boot.sh calls addon scripts with "kill" on shutdown/restart - full teardown.
if [ "$1" = "kill" ]; then
    for p in $(ps 2>/dev/null | grep "[i]njectTone" | awk '{print $1}'); do
        kill -9 $p 2>/dev/null
    done
    if [ -f "$mmLD_PRELOAD_VAR" ]; then
        cat "$mmLD_PRELOAD_VAR" | tr " " "\n" | grep -v forceAudioIn | tr "\n" " " > /tmp/.p
        mv /tmp/.p "$mmLD_PRELOAD_VAR"
    fi
    exit 0
fi

# ── ARM THE TAP FIRST ──────────────────────────────────────
if [ -f "$mmLD_PRELOAD_VAR" ]; then
    FC=$(cat "$mmLD_PRELOAD_VAR" | tr " " "\n" | grep -v forceAudioIn | tr "\n" " ")
    echo "$LIB $FC" > "$mmLD_PRELOAD_VAR"
else
    echo "$LIB" > "$mmLD_PRELOAD_VAR"
fi

# ── settings ───────────────────────────────────────────────
FREQ=440
GAIN=0.2
CHANNELS=1
[ -f "$APPDIR/config" ] && . "$APPDIR/config"

# ── start the injector NOW, not after MPC comes up ─────────
# injectTone creates the shared-memory ring at its own startup (near-
# instant). forceAudioIn.so's constructor - which needs that ring to already
# exist - runs the moment MPC's process is exec'd, which happens later in
# boot.sh's own sequence. Waiting for "MPC Main Thread" here (as
# ForceLinkAudio does for its *network* process, which has no such
# ordering requirement) loses that race every time: MPC would always see
# passthrough-only. The ring absorbs whatever accumulates before MPC starts
# consuming it, so starting early is always safe.
"$APPDIR/injectTone" "$FREQ" "$GAIN" "$CHANNELS" \
    > /tmp/injectTone.log 2>&1 &
