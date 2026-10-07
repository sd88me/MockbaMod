#!/bin/sh
# Read-only network diagnostic for the Force under MockbaMod. Changes nothing.
# Checks whether the connman crash-loop fix is still in place, and whether
# the MockbaMod /usr overlay is feeding connmand/iwd different shared libs
# than stock (the main thing that differs between card-in and card-out).
#
# Run ON THE FORCE as root, e.g.:
#   ssh root@<force-ip> sh -s < scripts/diag-network.sh > net-diag.txt

echo "===== 1. crash-loop fix (scripts/fix-connman-crashloop.sh) ====="
grep -n 'OnlineCheck' /etc/connman/main.conf 2>&1
echo "--- override.conf"
cat /etc/systemd/system/connman.service.d/override.conf 2>&1
echo "--- service state"
systemctl show connman.service -p ActiveState,SubState,NRestarts,ExecMainStartTimestamp
systemctl show iwd.service -p ActiveState,SubState,NRestarts 2>/dev/null

echo
echo "===== 2. crashes this boot ====="
journalctl -b -u connman.service --no-pager 2>/dev/null | grep -iE 'abort|signal|segv|online|error|dhcp' | tail -40
journalctl -b -u iwd.service --no-pager 2>/dev/null | grep -iE 'abort|signal|segv|error' | tail -15
echo "eth0 link-down count this boot: $(dmesg | grep -c 'eth0: Link is Down')"

echo
echo "===== 3. /usr overlay ====="
mount | grep -E ' on /usr | on /tmp/usr '
UPPER=/media/az01-internal/system/usr/overlay
echo "--- persistent writes in overlay upperdir ($UPPER/lib), symlinks first"
ls -la "$UPPER/lib" 2>/dev/null | grep -- '->'
ls "$UPPER/lib" 2>/dev/null | grep -vE '^\.' | head -n 50

echo
echo "===== 4. libs connmand / wpa_supplicant actually loaded ====="
# No ldd on the Force, so read the live process maps. A lib that resolves to
# the SD card, or that exists in usr.img or the upperdir, differs from stock.
for proc in connmand wpa_supplicant; do
    pid=$(pidof "$proc") || continue
    echo "--- $proc ($pid)"
    awk '{print $6}' "/proc/$pid/maps" | grep / | sort -u | while read -r path; do
        name=$(basename "$path")
        flag=""
        case "$path" in /media/*) flag="$flag SD-CARD-LIB" ;; esac
        [ -e "/tmp/usr/lib/$name" ] && flag="$flag from-usr.img"
        [ -e "$UPPER/lib/$name" ] && flag="$flag from-upperdir"
        echo "  $path${flag:+   <<<$flag}"
    done
done

echo
echo "===== 4b. WiFi chip / LoadPin ====="
dmesg | grep -E 'LoadPin: firmware denied|bus is down|card 0001 removed'
mount | grep -E ' on /usr/lib/(firmware|modules) '

echo
echo "===== 5. live state ====="
ip -4 addr show eth0 2>&1; ip -4 addr show wlan0 2>&1
ip route 2>&1
connmanctl services 2>&1 | head -n 10
echo "--- network-ish processes"
ps | grep -E '[c]onnman|[i]wd|[w]pa_supp|[a]vahi|[r]tpmidid|[d]hcp|[u]dhcpc'
