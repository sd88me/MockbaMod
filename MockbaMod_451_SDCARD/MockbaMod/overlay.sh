#!/bin/sh
#Author: MockbaTheBorg & Amit Talwar
#Description: This is File SYstem Overlay Script for mockbamod required for mounting
# certain folders and images as system overlays.

# Part of Mockba Mod, do not modify

# Set up the environment
mmPath=$(cat /dev/shm/.mmPath)
. $mmPath/MockbaMod/env.sh

if test -f $mm/automount; then

	echo "Mounting Writable /usr via OverlayFS..."
	mkdir -p /media/az01-internal/system/usr/
	mkdir -p /media/az01-internal/system/usr/overlay/
	mkdir -p /media/az01-internal/system/usr/.work/
	mkdir -p /tmp/usr
	mkdir -p /media/az01-internal/system/root/overlay
	mkdir -p /media/az01-internal/system/root/.work

	#mount root as overlay
	mount -t overlay -o rw,relatime,lowerdir=/root,upperdir=/media/az01-internal/system/root/overlay,workdir=/media/az01-internal/system/root/.work overlay /root

	if ! mount | grep -q "/tmp/usr"; then
		mount -o loop $mmFiles/usr.img /tmp/usr
	fi
	sleep .5
	mount -t overlay -o rw,relatime,lowerdir=/tmp/usr:/usr,upperdir=/media/az01-internal/system/usr/overlay,workdir=/media/az01-internal/system/usr/.work overlay /usr

	if ! mount | grep -q "overlay on /usr"; then
		echo "OverlayFS mounting failed!"
	fi

	# Kernel LoadPin only allows firmware/modules loaded from the pinned
	# read-only root fs. Through the /usr overlay they're denied, so if the
	# WiFi chip resets mid-session (it does when connman crash-restarts) its
	# firmware reload fails and WiFi is gone until reboot. Bind the stock
	# firmware/modules dirs back over the overlay so they stay on the root fs.
	mkdir -p /run/stockroot
	mount | grep -q " /run/stockroot " || mount --bind / /run/stockroot
	for d in lib/firmware lib/modules; do
		[ -d "/run/stockroot/usr/$d" ] && mount --bind "/run/stockroot/usr/$d" "/usr/$d"
	done
	#mount if special emmc-overlay being used. under alpha testing , not publically available!
	if test -f "$mmPath/emmc-overlay.sh"; then
		"$mmPath/emmc-overlay.sh" &
	fi

else
	echo "Overlay not mounted."
fi
