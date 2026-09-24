#!/bin/sh

appname=drmvncserver
appTitle=DrmVncServer
appDir=DrmVncServer

FPS=0
ff=vffmpeg #symlink alias for ffmpeg so it does not clash with other rruning processes.

card=$(find  /sys/devices/platform/display-subsystem/drm -type d -maxdepth 1 -iname "card*" |xargs| cut -d"/" -f7)

echo "Your graphics Card is: $card" 


################ NO NEED TO EDIT BELOW THIS LINE ###############

mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh

runDir="$mmPath/AddOns/"
installroot="$mmPath/AddOns/$appDir/"
runScript="$runDir/run_$appname.sh"
mode=$1
binn=vncdrm
bint=/usr/bin/$binn

export LD_LIBRARY_PATH="$installroot":$LD_LIBRARY_PATH

echo "
***********************************************************
*   $appTitle AddOn Manager for Mockba Mod               *
***********************************************************
*   VncServer  Credits/courtesy:                          *
*   Kikgen Labs <https://github.com/TheKikGen>            *
***********************************************************

"

EVENT() {

    echo "$(sed -n "$(($(cat /proc/bus/input/devices | grep -ni "$1" | cut -d: -f1) + 4))"p /proc/bus/input/devices | grep -Eo 'event[0-9]+')"
}

DISABLE() {

    killall "$appname" 2>/dev/null
    # killall $ff 2> /dev/null
    rm -f "$runScript"

    echo "$appTitle has been Stopped and removed from Auto Launch"
}

if [ "$mode" == "DISABLE" ]; then
    DISABLE
fi

if [ "$mode" == "ENABLE" ]; then
    killall "$appname" 2>/dev/null

    if [ ! -f $bint ]; then
        cp "$installroot"$binn $bint
        chmod +x $bint
    fi

    ln -sf "$installroot/drmvncserver" "/usr/bin/drmvncserver" 2>/dev/null

    # Symlink the bundled shared libs into /usr/lib so drmvncserver resolves
    # them via the default linker search path, not just LD_LIBRARY_PATH.
    # Needed because nodeServer's Modules page spawns the binary directly
    # (no env, no wrapper script) - without this it dies instantly with a
    # "cannot open shared object file" error and the page's toggle silently
    # does nothing.
    for lib in "$installroot"*.so*; do
        [ -f "$lib" ] && ln -sf "$lib" "/usr/lib/$(basename "$lib")" 2>/dev/null
    done
    ldconfig 2>/dev/null

    # Manual start only: run directly from installroot, never install a
    # top-level AddOns/run_$appname.sh, so nothing auto-starts on boot.
    rm -f "$runScript"
    "$installroot/run_$appname.sh"

    sleep 1
    echo
    echo "$appTitle is now running (manual start only, no auto-start on boot)."
    echo "Run 'vncdrm STOP' (or manage.sh DISABLE) to stop it."
    sleep 3
    echo
    exit 0

fi

if [ "$mode" == "UNINSTALL" ]; then

    if [[ -e "$installroot" ]]; then
        DISABLE

        #rm "/usr/bin/$appname" 2>/dev/null
        #rm "$bint" 2>/dev/null 3>/dev/null

        libs=$(find "$installroot" -type f -maxdepth 1 -name "*.so*")
        for lib in $libs; do
            liblink=/usr/lib/$(basename "$lib")
            rm "$liblink" 2>/dev/null
        done
        ldconfig 2>/dev/null

        # rm "/usr/bin/$appname" 2>/dev/null
        # rm "$bint" 2>/dev/null
        echo "<<<< $appTitle has been UnInstalled."
        echo
    fi
fi
