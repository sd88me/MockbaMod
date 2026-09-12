#!/bin/sh
appname=mockbaMagic
appTitle=mockbaMagic
appDir=mockbaMagic

################ NO NEED TO EDIT BELOW THIS LINE ###############

mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh

runDir="$mmPath/AddOns/"
installroot="$mmPath/AddOns/$appDir/"
runScript="$runDir/run_$appname.sh"
mode=$1

echo "
***********************************************************
*   $appTitle AddOn Manager for Mockba Mod      *
***********************************************************
"
if [ "$mode" == "UNINSTALL" ]; then

    if [[ -e "$installroot" ]]; then
        rm -f "$runScript" 2>/dev/null
        rm -rf "$installroot/" 2>/dev/null
        echo "<<<< $appTitle has been UnInstalled."
        echo "Restarting Force Application "
        systemctl restart inmusic-mpc
    fi
fi

if [ "$mode" == "DISABLE" ]; then

    rm -f "$runScript"
    echo "$appTitle has been disabled"
    echo "Restarting Force Application "
    systemctl restart inmusic-mpc
fi

if [ "$mode" == "ENABLE" ]; then

    cp -f "$installroot/run_$appname.sh" "$runScript"
    echo "$appTitle has been enabled"
    echo "Restarting Force Application.."
    systemctl restart inmusic-mpc

fi
