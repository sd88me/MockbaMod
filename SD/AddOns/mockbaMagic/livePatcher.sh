#!/bin/sh
base=$(dirname "$0")
PID=-1 #real pid should be greater than 0 for active process.
MPC=
GETMPC() {
echo $(ps  | grep  -m1  "{MPC Main Thread}" | grep -v grep | xargs | cut -d" " -f1)
}
READY() {
    MPC=$(GETMPC)

    while test -z "$MPC"; do
        MPC=$(GETMPC)
 #      echo "MPC IS: " $MPC
 #       echo "Waiting Force Process"
        sleep 0.05
    done

    PID="$MPC"
}



READY
echo "sending pid of [$PID]"
echo ""
 "$base"/mockbaMagic $PID

