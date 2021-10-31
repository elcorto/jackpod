#!/bin/sh

set -eu

prog=$(basename $0)

here=$(dirname $(readlink -f $0))
. $here/settings.sh
. $here/lib.sh

# XXX make jackpod always write local logfile, but remote only when -d
#
# better: fetch connection status from some jack sommand instead of parsing
# logfiles #oldskool
#
# local log msg in case of connection error (both jacks run, but sound from
# pulse sink aborts due to network foo,
# solution: restart pulse sink: jackpod -rp)
#
#   Recv fd = 7 err = Resource temporarily unavailable
#   Recv connection lost error
#   Driver is restarted
#   JackTimedDriver::Process XRun = 835 usec
#   Restarting driver...
#   NetDriver started in sync mode without Master's transport sync.
#   Waiting for a master...
#   Initializing connection with raspberrypi...
#   **************** Network parameters ****************
#   Name : lebdob
#   Protocol revision : 8
#   MTU : 1500
#   Master name : raspberrypi
#   Slave name : lebdob
#   ID : 17
#   Transport Sync : no
#   Send channels (audio - midi) : 0 - 0
#   Return channels (audio - midi) : 2 - 0
#   Sample rate : 48000 frames per second
#   Period size : 512 frames per period
#   Network latency : 1 cycles
#   SampleEncoder : Float
#   Slave mode : sync
#   ****************************************************


grep_log_cnt(){
    grep -c 'Recv connection lost error' $log_fn
}


if [ -f $log_fn ]; then
    cnt=$(grep_log_cnt)
    while true; do
        this_cnt=$(grep_log_cnt)
        if [ $this_cnt -gt $cnt ]; then
            cnt=$this_cnt
            msg "restart pulse sink"
            # jackpod -rp
            restart_pulse_sink
        fi
        sleep 3
    done
else
    msg "$log_fn not found, skip"
fi
