#!/bin/sh
#
# ForceLocal - publishes the Force as force.local via mDNS.
# Standalone avahi-daemon (bundled binary+libs, reused from the rtpMIDI
# addon), D-Bus disabled - never touches shared /etc/dbus-1 policy.

appname=avahi-daemon
appTitle=ForceLocal
appDir=ForceLocal

mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh

runDir="$mmPath/AddOns/"
installroot="$mmPath/AddOns/$appDir/"
runScript="$runDir/run_forcelocal.sh"
mode=$1

if [ "$mode" == "ENABLE" ]; then
    cp -f "$installroot/run_forcelocal.sh" "$runScript"
    "$runScript"
    echo "$appTitle enabled - device should now answer as force.local"
fi

if [ "$mode" == "DISABLE" ]; then
    "$runScript" kill 2>/dev/null
    rm -f "$runScript"
    echo "$appTitle disabled"
fi

if [ "$mode" == "UNINSTALL" ]; then
    "$runScript" kill 2>/dev/null
    rm -f "$runScript"
    echo "$appTitle uninstalled"
fi
