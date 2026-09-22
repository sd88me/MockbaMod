#!/bin/sh
# Fix the connman online-check crash-loop that flaps WiFi/Ethernet under
# MockbaMod. See "Docs/Network Flapping (connman crash-loop) Fix.txt" for
# the full writeup of what this does and why.
#
# Run this ON THE FORCE as root (over SSH), e.g.:
#   python3 tmp_ssh.py <force-ip> "$(cat scripts/fix-connman-crashloop.sh)"
# Safe to re-run — it's idempotent and backs up originals before touching
# anything.

set -e

MAIN_CONF=/etc/connman/main.conf
OVERRIDE_DIR=/etc/systemd/system/connman.service.d
OVERRIDE_CONF="$OVERRIDE_DIR/override.conf"
STAMP=$(date +%Y%m%d%H%M%S)

if [ "$(id -u)" != "0" ]; then
    echo "Must run as root" >&2
    exit 1
fi

changed=0

# 1. Disable connman's crashing online-connectivity check.
if [ -f "$MAIN_CONF" ]; then
    if grep -q '^EnableOnlineCheck' "$MAIN_CONF" 2>/dev/null; then
        if grep -q '^EnableOnlineCheck[[:space:]]*=[[:space:]]*false' "$MAIN_CONF" 2>/dev/null; then
            echo "main.conf: EnableOnlineCheck already false, leaving as-is"
        else
            cp "$MAIN_CONF" "$MAIN_CONF.bak-$STAMP"
            sed -i 's/^EnableOnlineCheck.*/EnableOnlineCheck = false/' "$MAIN_CONF"
            echo "main.conf: rewrote existing EnableOnlineCheck line (backup: $MAIN_CONF.bak-$STAMP)"
            changed=1
        fi
    else
        cp "$MAIN_CONF" "$MAIN_CONF.bak-$STAMP"
        printf '\nEnableOnlineCheck = false\n' >> "$MAIN_CONF"
        echo "main.conf: appended EnableOnlineCheck = false (backup: $MAIN_CONF.bak-$STAMP)"
        changed=1
    fi
else
    mkdir -p /etc/connman
    printf '[General]\nEnableOnlineCheck = false\n' > "$MAIN_CONF"
    echo "main.conf: created with EnableOnlineCheck = false (no pre-existing file)"
    changed=1
fi

# 2. Guarantee unlimited auto-restart. connman has at least one more
#    SIGABRT trigger beyond the online check (a race in default-service
#    selection when eth0/wlan0 both come up around the same time) that
#    can't be patched here. Bounded restarts mean that crash can leave
#    connman permanently "failed" until a human restarts the Force —
#    worse than a brief flap. Always ensure the override reads exactly
#    this, regardless of what's there now.
WANT_OVERRIDE='[Unit]
StartLimitIntervalSec=0

[Service]
Restart=always
RestartSec=1
StartLimitBurst=0
'
mkdir -p "$OVERRIDE_DIR"
if [ -f "$OVERRIDE_CONF" ] && [ "$(cat "$OVERRIDE_CONF")" = "$(printf '%s' "$WANT_OVERRIDE")" ]; then
    echo "override.conf: already set to unlimited restart, leaving as-is"
else
    [ -f "$OVERRIDE_CONF" ] && cp "$OVERRIDE_CONF" "$OVERRIDE_CONF.bak-$STAMP"
    printf '%s' "$WANT_OVERRIDE" > "$OVERRIDE_CONF"
    echo "override.conf: set Restart=always/StartLimitBurst=0 (unlimited retries)$( [ -f "$OVERRIDE_CONF.bak-$STAMP" ] && echo ", backup: $OVERRIDE_CONF.bak-$STAMP")"
    changed=1
fi

if [ "$changed" = "1" ]; then
    systemctl daemon-reload
    systemctl restart connman.service
    echo "Reloaded systemd and restarted connman.service to apply changes."
else
    echo "Nothing to change — fix already in place."
fi

echo
echo "--- current state ---"
systemctl show connman.service -p MainPID,ActiveState,SubState,NRestarts
