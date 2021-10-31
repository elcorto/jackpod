#!/bin/sh


set -u

here=$(dirname $(readlink -f $0))
. $here/../settings.sh
. $here/../lib.sh

prog=$(basename $0)

msg "user: $USER $(id -u)"

# Only if we had it running before
if pactl list sinks | grep -q jack_out; then
    if ps aux | grep -q jackd; then
        max=30
        have_network=false
        for x in $(seq $max); do
            # Poor man's way to wait for network b/c we did not figure out how
            # to set up jackpod-restart-pulse-sink.service to reliably start
            # after we have network.
            ping -c1 raspi > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                have_network=true
                break
            else
                msg "sleep $x/$max, waiting for network"
                sleep 1
            fi
        done
        if ! $have_network; then
            err "no network, can't ping"
        fi
        # Time to re-establish jack connection once we have network. Awful and
        # hackish. We need a way to test whether the jack connection is up. If
        # we restart the sink before that, we get in syslog
        #    lebdob pulseaudio[908]: E: [pulseaudio] module-jack-sink.c: Not enough physical output ports, leaving unconnected.
        # when doing
        #   pactl load-module module-jack-sink
        # but the exit code of this is always zero. If we at least could detect
        # if the loading worked. Then we could re-try in a loop.
        sleep 5
        msg "restarting jack pulse sink"
        # same as jackpod -rp
        restart_pulse_sink
        msg "exit code of restart_pulse_sink: $?"
    else
        msg "no jackd running"
    fi
else
    msg "no jack_out"
fi
