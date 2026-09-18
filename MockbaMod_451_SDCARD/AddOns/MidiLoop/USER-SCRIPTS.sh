## you assign the script to shotcuts in midiloop config.
#forExample : SHIFT+EDIT+UP=SCRIPT-10 #will reboot force as that is wha script 10 is set to do.

if [ "$ID" = "SCRIPT-1" ]; then #SCRIPT-1
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #Toggle NodeServer on/Off
    if $(ps | grep -v grep | grep -q nodeServer); then
        echo "NodeServer Running so Killing it!"
        kilall node 2>/dev/null
        /media/662522/AddOns/nodeServer/run_nodeserver.sh kill
    else
      nohup /media/662522/AddOns/nodeServer/run_nodeserver.sh

    fi

    #YOUR SCRIPT ENDS ABOVE HERE ##################
    exit 0
fi

if [ "$ID" = "SCRIPT-2" ]; then #SCRIPT-2
    #YOUR SCRIPT STARTS BELOW HERE ###################

    #if you have vnc drm addon installed, it will start your vnc drm server
    app=drmvncserver
    if $(ISRUNNING $app); then
        /media/662522/AddOns/DrmVncServer/manage.sh DISABLE
    else
        /media/662522/AddOns/DrmVncServer/manage.sh ENABLE

    fi

    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-3" ]; then # #SCRIPT-3
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #toggles harpie4t if installed
    app=harpie4t
    if $(ISRUNNING $app); then
        killall $app
    else
      nohup  "/media/662522/AddOns/Harpie4T/$app" -v &
    fi
    #YOUR SCRIPT ENDS ABOVE HERE ###################

    exit 0

fi

if [ "$ID" = "SCRIPT-4" ]; then #SCRIPT-4
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #toggles riffmaker if installed
    app=riffmaker4t
    if $(ISRUNNING $app); then
        killall $app
    else
      nohup "/media/662522/AddOns/RiffMaker4T/$app" -v &
    fi

    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-5" ]; then #SCRIPT-5
    #YOUR SCRIPT STARTS BELOW HERE ###################

    #toggles euclidier if installed
    app=euclidier
    if $(ISRUNNING $app); then
        killall $app
    else
        "/media/662522/AddOns/Euclidier/$app" -v &
    fi

    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-6" ]; then #SCRIPT-6
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #TOGLE BETWEEN AKAI NETOWRK MIDI AND rtpMIDi
    #make sure you enable rtpMidi via ADM first.
    "/media/662522/AddOns/rtpMIDI/run_rtpMIDI.sh" TOGGLE &

    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-7" ]; then #SCRIPT-7
    #YOUR SCRIPT STARTS BELOW HERE ###################

    #create systemlog dump in mockba sd card, useful for diagnostics.
    journalctl -x >/media/662522/journalLog.txt

    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-8" ]; then #SCRIPT-8
    #YOUR SCRIPT STARTS BELOW HERE ###################
bfile=/dev/shm/USEALTMPC
if [[ -f "$bfile"  ]]; then
rm -f "$bfile"
else
touch "$bfile"
fi

systemctl restart acvs

exit 0

    ## This SCRIPT TOGGLES DEV-MODE ON/OFF ON FORCE (dev mode will allow mouse�)
    ##You will need to Restart Force App to see changes..

    devF=/media/az01-internal/dev-mode
    if [ -f "$devF" ]; then
        rm -f "$devF"
    else
        touch "$devF"
    fi

    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-9" ]; then #SCRIPT-9
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #restarts force program (like a new project)
    systemctl restart acvs
    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-10" ]; then #SCRIPT-10
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #reboot the device
    shutdown -r now

    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-11" ]; then #SCRIPT-11
    #YOUR SCRIPT STARTS BELOW HERE ###################
   # Toggle Display backlight on/of
BL=/sys/class/backlight/mipi-backlight/bl_power
BLV=$(cat "$BL")
if [[ "$BLV" == 1 ]]; then
echo 0 > "$BL"
else
echo 1 > "$BL"
fi




    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-12" ]; then #SCRIPT-12
    #YOUR SCRIPT STARTS BELOW HERE ###################
	#toggle screen brightness between dim and high
     LO=50
     HI=180  #max brightness is 255
      BN=/sys/class/backlight/mipi-backlight/brightness 
 B=$(cat $BN)
echo "Current Screen Brightness: $B"
if [[ "$B" -lt "$HI" ]]; then
	echo "$HI" > $BN
else
	echo "$LO" > $BN
fi 

	  
  #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-13" ]; then #SCRIPT-13
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #shutdown force
    shutdown -h
    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-14" ]; then #SCRIPT-14
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #toggles the DX7 voice (ForceDX7 / dx7_host) - requires ForceAudioIn enabled
    app=dx7_host
    if $(ISRUNNING $app); then
        killall $app
    else
        nohup /media/662522/AddOns/ForceDX7/dx7_host \
            --module-dir /media/662522/AddOns/ForceDX7 \
            --ctrl-sock /tmp/dx7_ctrl.sock \
            --control-channel 1 \
            --mix-slot 2 \
            >/tmp/dx7_host.log 2>&1 &
    fi
    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-15" ]; then #SCRIPT-15
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #toggles the JV-880 voice (ForceJV880 / jv_host) - requires ForceAudioIn enabled
    app=jv_host
    if $(ISRUNNING $app); then
        killall $app
    else
        nohup /media/662522/AddOns/ForceJV880/jv_host \
            --module-dir /media/662522/AddOns/ForceJV880 \
            --ctrl-sock /tmp/jv880_ctrl.sock \
            --control-channel 1 \
            --mix-slot 1 \
            >/tmp/jv_host.log 2>&1 &
    fi
    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-16" ]; then #SCRIPT-16
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #toggles the Maze Voice synth (ForceMazeVoice / maze_host) - requires ForceAudioIn enabled
    app=maze_host
    if $(ISRUNNING $app); then
        killall $app
    else
        nohup /media/662522/AddOns/ForceMazeVoice/maze_host \
            --module-dir /media/662522/AddOns/ForceMazeVoice \
            --ctrl-sock /tmp/maze_ctrl.sock \
            --control-channel 1 \
            >/tmp/maze_host.log 2>&1 &
    fi
    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-17" ]; then #SCRIPT-17
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #toggles the Maze Sequencer (ForceMazeSeq / maze_seq_host)
    app=maze_seq_host
    if $(ISRUNNING $app); then
        killall $app
    else
        nohup /media/662522/AddOns/ForceMazeSeq/maze_seq_host \
            --module-dir /media/662522/AddOns/ForceMazeSeq \
            --ctrl-sock /tmp/maze_seq_ctrl.sock \
            --control-channel 1 \
            >/tmp/maze_seq_host.log 2>&1 &
    fi
    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi

if [ "$ID" = "SCRIPT-18" ]; then #SCRIPT-18
    #YOUR SCRIPT STARTS BELOW HERE ###################
    #toggles the Acid Sequencer (ForceAcid / force-acid)
    app=force-acid
    if $(ISRUNNING $app); then
        killall $app
    else
        CONF=/media/662522/AddOns/ForceAcid/force-acid.conf
        CONF_ARG=""
        [ -f "$CONF" ] && CONF_ARG="--config $CONF"
        nohup /media/662522/AddOns/ForceAcid/force-acid $CONF_ARG >/tmp/force-acid.log 2>&1 &
    fi
    #YOUR SCRIPT ENDS ABOVE HERE ###################
    exit 0
fi
