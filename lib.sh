cmd_stop_jack_remote=$(cat <<-EOF
    for sig in 15 9; do
        pkill -\$sig -f 'jackd.*-d'
        pkill -\$sig -f 'jackd.*-ndefault'
        pkill -\$sig jack_load
    done
EOF
)

err(){
    echo "$prog: error: $@"
    exit 1
}

msg(){
    echo "$prog: $@"
}

yesno(){
    [ $1 -eq 0 ] && echo "yes" || echo "NO"
}

checkopt(){
    what=$1
    val=$2
    [ "$what" = "$none" ] && return 1
    echo "$what" | grep -q $val
    return $?
}

start_jack_local(){
    jackd $local_opts -P80 -d net $local_driver_opts >> $log 2>&1 &
    ps aux | grep jackd >> $log 2>&1
}


stop_jack_local(){
    for sig in 15 9; do
        pkill -$sig -f 'jackd.*-d'
        pkill -$sig -f 'jackd.*-ndefault'
    done
}

# The action of stop_jack_remote is performed in the ssh below so that we don't
# need to ssh twice, which would be slower.
restart_jack_remote(){
    eval "$ssh_cmd" <<-EOF
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
        (
        echo "kill ..."
        $cmd_stop_jack_remote
        echo "start jackd ..."
        jackd $remote_opts -P80 -d alsa --device $remote_device \
           $remote_driver_opts &
        while ! pgrep -f 'jackd.*-P.*-d.*alsa.*--device'; do
            echo '\$(date) waiting for jackd ...'
            sleep 0.1
        done
        echo "load netmanager ..."
        jack_load netmanager -i -c
        ps aux | grep jackd
        ) >> $log 2>&1
EOF
}

stop_jack_remote(){
    eval "$ssh_cmd" <<-EOF
        (
        $cmd_stop_jack_remote
        ) >> $log 2>&1
EOF
}

stop_jack(){
    stop_jack_local
    stop_jack_remote
}

check_broken_pulse(){
    if ! pactl list sinks > /dev/null 2>&1; then
        err "pulseaudio broken, try '$prog -kP'"
    fi
}

stop_pulse(){
    systemctl --user stop pulseaudio.service pulseaudio.socket
}

restart_pulse(){
    systemctl --user restart pulseaudio.service
}

start_pulse_sink(){
    # This is only useful if local and remote jackds are already running in
    # netjack2 mode (-rj), else a local jackd with default args is started
    # (jackd -T -ndefault -T -d alsa), which is useless.
    check_broken_pulse
    if ! pactl list sinks | grep -q jack_out; then
        pactl load-module module-jack-sink >> $log 2>&1
        pactl set-sink-mute jack_out false
    fi
}

stop_pulse_sink(){
    check_broken_pulse
    if pactl list modules | grep -q module-jack-sink; then
        pactl unload-module module-jack-sink
    fi
}

restart_pulse_sink(){
    stop_pulse_sink
    sleep 0.5
    start_pulse_sink
}


do_check_status(){
    check_broken_pulse
    (
    eval "$ssh_cmd" <<-EOF
        yesno(){
            [ \$1 -eq 0 ] && echo "yes" || echo "NO"
        }
        pgrep -f 'jackd.*-P.*-d.*alsa.*--device' > /dev/null
        echo "remote jackd: \$(yesno \$?)"
EOF
    pgrep -f 'jackd.*-P.*-d.*net' > /dev/null
    echo "local jackd: $(yesno $?)"
    pactl list sinks | grep -q jack_out
    echo "jack_out sink: $(yesno $?)"
    ) | column -t -s:
}
