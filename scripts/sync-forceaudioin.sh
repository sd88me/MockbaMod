#!/bin/sh
# Sync the ForceAudioIn addon into SD/AddOns/ForceAudioIn/.
#
# ForceAudioIn's source now lives in its own repo
# (github.com/sd88me/force-audioin, split out of force-maze 2026-09-17).
# This fork no longer commits the built addon (see .gitignore) - it only
# carries a synced copy of that repo's addon/ build output. Run this before
# mastering an SD card or deploying to a device.
set -eu
cd "$(dirname "$0")/.."

SRC="${FORCE_AUDIOIN_REPO:-../force-audioin}/addon"
DEST="SD/AddOns/ForceAudioIn"

if [ ! -d "$SRC" ]; then
    echo "force-audioin repo not found at $SRC (clone" \
         "github.com/sd88me/force-audioin.git next to this repo, or set" \
         "FORCE_AUDIOIN_REPO to its path)." >&2
    exit 1
fi

mkdir -p "$DEST"
cp "$SRC/NSMODULE.json" "$SRC/manage.sh" "$SRC/run_ForceAudioIn.sh" \
   "$SRC/forceAudioIn.so" "$SRC/injectTone" "$DEST/"
chmod 0755 "$DEST/manage.sh" "$DEST/run_ForceAudioIn.sh" \
    "$DEST/forceAudioIn.so" "$DEST/injectTone"

echo "Synced ForceAudioIn: $SRC -> $DEST"
