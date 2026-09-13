#!/bin/sh
#Author: MockbaTheBorg & Amit Talwar
#Description: This is your mockbamod Initial Boot Script. From OS Bootstrap Script
# control is transferred to this script and this script handles the rest.
# this script is run every time you create a new project and thus any addons started by it are also
# restarted. any manually Started Addons by midiloop will alos close and need to be manually restarted.

# Critical Part of Mockba Mod, do not modify

# Set the initial execution path
cd "$(dirname "$0")"
echo $(pwd) >/dev/shm/.mmPath

# Set up the environment
mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh

clear_pads

if [ -f "$mmPath/emmc-repair.sh" ]; then
	mv "$mmPath/emmc-repair.sh" /tmp/
	chmod +x /tmp/emmc-repair.sh
	/tmp/emmc-repair.sh >"$mmPath/emmc.log"

fi

echo "------------------------------" >$mmLogs/boot.log
date >>$mmLogs/boot.log

if test -f /tmp/mod_started; then
	echo "Mod was already started" >>$mmLogs/boot.log
else #first boot
	echo "MockbaMod SD Card is mounted on "$mmMount
	echo "Booting up the mod" >>$mmLogs/boot.log

	set_pad 00 00 05 05
	# Start logo video
	echo "Logo video" >>$mmLogs/boot.log
	play_back $mmVideos/logo.mp4
	#	sleep .5
	set_pad 00 00 20 20
	set_pad 01 00 05 05

	# Mount the /usr overlay
	echo "Mount /usr overlay" >>$mmLogs/boot.log
	f=$mm/overlay.sh
	[ -f "$f" ] && "$f"
	#	sleep .5
	set_pad 01 00 20 20
	set_pad 02 00 05 05

	# Enable SSHD
	echo "Enable sshd" >>$mmLogs/boot.log
	systemctl enable sshd
	sleep .5
	set_pad 02 00 20 20
	set_pad 03 00 05 05

	# Restart SSHD
	echo "Restart sshd" >>$mmLogs/boot.log
	systemctl restart sshd
	sleep .5
	set_pad 03 00 20 20
	set_pad 04 00 05 05

	# Checks and runs runonce.sh
	echo "Check/run runonce" >>$mmLogs/boot.log
	f=$mmPath/runonce.sh
	[ -f "$f" ] && "$f"
	mv -f "$f" $mmPath/runonce.bak 2>/dev/null
	#sleep .5
	set_pad 04 00 20 20
	set_pad 05 00 05 05

	# Checks and runs autoexec.sh
	echo "Check/run autoexec" >>$mmLogs/boot.log
	f=$mmPath/autoexec.sh
	[ -f "$f" ] && "$f"
	#sleep .5
	set_pad 05 00 20 20
	set_pad 06 00 05 05

	# Waits for logo video to finish playing
	echo "Waiting for logo video to end" >>$mmLogs/boot.log
	while [ $(ps | grep ffmpeg | wc -l) -gt 1 ]; do
		killall ffmpeg 2>/dev/null
		echo "ffmpeg was running so killed" >>$mmLogs/boot.log
		#sleep .5
	done

	display $mmImages/wait.png

	#checkks if eemc has errors and if errors found. runs emmc repair script and shuts down.
	if [ $(EMMCSCAN) != "EMMC-OK" ]; then
		echo "Your EMMC is Corrupt"

		display $mmTools/emmc-fix/status.png

		"$mmTools/emmc-fix/emmcRepair"

		shutdown -h

	fi

	# First installation script
	echo "Check/run install" >>$mmLogs/boot.log
	set_pad 06 00 20 20
	set_pad 07 00 05 05
	#checks if mod is installed if not installs it.
	#if your emmc is corrupt this is where the boot loop happens
	f=$mm/install.sh
	[ -f "$f" ] && "$f"

	touch /tmp/mod_started
	set_pad 07 00 20 20
	systemctl restart iwd

	#midicheckeer if midi does not load on first start restarts acvs service!
	$mmPath/MockbaMod/midicheck.sh &
fi
#ifconfig wlan0 up #manually start wifi (not required, is here for debugging)

# Kills AddOns if still running
echo "Killing AddOns" >>$mmLogs/boot.log
if test -d $mmPath/AddOns; then
	for f in $mmPath/AddOns/*.sh; do
		echo "$f kill" >>$mmLogs/boot.log
		"$f" kill 2>/dev/null
	done
fi

#remount all required volumes.
$mmPath/MockbaMod/remounter.sh

#Loads AddOns (runs any scripts inside AddOns Folder root.)
echo "Loading AddOns" >>$mmLogs/boot.log
if test -d $mmPath/AddOns; then
	for f in $mmPath/AddOns/*.sh; do
		echo "$f" >>$mmLogs/boot.log
		"$f" &
	done
fi

$mmPath/MockbaMod/remounter.sh

# Wait for every addon's LD_PRELOAD write to actually finish before
# reading it below - a fixed `sleep 1` here is NOT always enough (confirmed
# live 2026-09-13: MPC exec'd with a stale $mmLD_PRELOAD_VAR - missing an
# entry that WAS in the file moments later - even with every writer's own
# read-modify-write correctly mkdir-lock-protected against each other; the
# lock stops writers clobbering each other, it does nothing to guarantee
# they're all done by the time this fixed read happens).
#
# Just polling "is the lock free right now" isn't enough either (tried,
# confirmed still insufficient live) - the lock can be momentarily free
# between two DIFFERENT addons' sequential turns (one releases it a moment
# before the next acquires it), which looks identical to "everyone's done"
# from a bare presence check. So this waits for the file's own CONTENT to
# be unchanged across several consecutive checks, not just for the lock to
# be free at one instant - if another addon is still queued to write, the
# content changes on the next check and the stability streak resets.
# Bounded (~4s worst case) so a stale/crashed lock can never hang boot
# forever - degrades to roughly the old fixed sleep in the worst case,
# never hangs longer.
sleep 0.3
prev=""
stable=0
i=0
while [ $i -lt 40 ]; do
	i=$((i + 1))
	cur=""
	[ -f "$mmLD_PRELOAD_VAR" ] && cur=$(cat "$mmLD_PRELOAD_VAR")
	if [ -d /dev/shm/.LD_PRELOAD.lock ]; then
		stable=0
	elif [ "$cur" = "$prev" ]; then
		stable=$((stable + 1))
		[ $stable -ge 3 ] && break
	else
		stable=0
	fi
	prev="$cur"
	sleep 0.1
done
echo "LD_PRELOAD settle: $i checks, final content: $cur" >>$mmLogs/boot.log
#setSetting "MidiLearnPreviousMapping" "/media/az01-internal-sd/Force Documents/Midi Learn/NI AmitLP2-Ch11_n.xmm"

# Start the MPC Process
#we check if USEALTMPC FILE is PRESENT in RAM (created from midiloop Script,
#If present, alternate MPC binary (named MPC) is loaded from 662522/MockbaMOd/ALTMPC)
#This is so you can load a older version on a newer os or newer version on an older os
# if compatible with OS.
exeFile=/usr/bin/MPC
bfile=/dev/shm/USEALTMPC
if [[ -f "$bfile" ]]; then
	xFile=/media/662522/MockbaMod/ALTMPC/MPC
	if [[ -f "$xFile" ]]; then
		echo "Launching alternate MPC Binary: $xFile"
		exeFile="$xFile"
	else
		echo "Alternate Binary: $xFile NOT FOUND!! Loading Default Binary: $exeFile "..
	fi
fi

ulimit -S -s 1024
export MALLOC_ARENA_MAX=1

echo 0 >/proc/sys/kernel/randomize_va_space

[[ -f "$mmANYCTL_VAR" ]] && export ANYCTRL_NAME="$(cat "$mmANYCTL_VAR")"
[[ -f "$mmLD_PRELOAD_VAR" ]] && export LD_PRELOAD="$(cat "$mmLD_PRELOAD_VAR")"

#  setarch -R
#/usr/bin/MPC "$@"

echo "Launching  $exeFile"
"$exeFile" "$@"

# Kills AddOns
echo "Killing AddOns" >>$mmLogs/boot.log
if test -d $mmPath/AddOns; then
	for f in $mmPath/AddOns/*.sh; do
		echo "$f kill" >>$mmLogs/boot.log
		"$f" kill 2>/dev/null
	done
fi
