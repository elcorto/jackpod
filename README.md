About
=====

Control a realtime
[netjack2](https://github.com/jackaudio/jackaudio.github.com/wiki/WalkThrough_User_NetJack2)
connection between two machines.

Usage
=====

Use the `jackpod` command to set up a netjack2 connection (`jackpod -rj`) and
optionally start a pulseaudio sink (`jackpod -rp`, see `pactl list sinks`).


    jackpod [-S | -k (jpP) | -r (jpP) ] [-w -d]

    j = local and remote jackds in netjack2 mode
    p = pulseaudio sink "jack_out"
    P = pulseaudio service

    options:
        -S       : show status
        -k (jpP) : kill stuff
        -r (jpP) : start or restart
        -w       : wifi mode (use more buffering, pay with increased AV delay)
        -d       : debug mode: write a logfile /tmp/jack.log on the local and remote
                   machine

    -rp: when we resume from suspend (to ram) mode, then the jackd connection
    (netjack2) is still active and only the pulse sink needs a restart -> no need
    to kill the jackds, which takes a bit longer.

    examples:

        This is what you call when you need to start all
            $ jackpod -rjp

        Check status
            $ jackpod -S
            remote jackd    yes
            local jackd     yes
            jack_out sink   yes

        (Re)start all, including pulseaudio
            $ jackpod -rjpP

        Disable pulse sink
            $ jackpod -kp
            $ jackpod -S
            remote jackd    yes
            local jackd     yes
            jack_out sink   NO

        Restart only pulse sink (e.g. after resuming from suspend mode)
            $ jackpod -rp

        Activate wifi settings:
            $ jackpod -rjp -w

See `README_jack.md` for details.

The sound flow is either (no pulse sink):

app (e.g. `mpv --ao=jack`) -> jackd (slave) -- LAN --> jackd
(master) -> sound card

or with the pulse sink `jack_out`:

app (e.g. `mpv --audio-device=pulse/jack_out`, browser, ...) ->
pulseaudio -> jackd (slave) -- LAN --> jackd (master) -> sound
card

For sound sources that cannot select the backend they play on (such as the
browser, and unlike `mpv` which can do that), use pulseaudio's `pavucontrol`
tool to redirect sound to the sink called "Jack sink (PulseAudio JACK Sink)",
which is the `jack_out` sink created with `jackpod -rp`.

Latency, WiFi, defaults
=======================

We hard-coded some values such as

* the master's sound card -- in our case a Raspberri Pi with a
  [Hifiberry DAC](https://www.hifiberry.com/shop/boards/hifiberry-dac-pro)
* values which influence the latency

so YMMV. Please just hack the values to fit your setup.


Note that netjack2 is designed to be run over a stable cable connection. We
achieve very low latency with no perceptible AV (audio-video) delay in this
case -- important for video! There is the `-w` (WiFi mode) option which sets
looser options (more buffering) that will increase the AV-delay a bit. This
will need to be adjusted for your network. So far, we had stable connections
only via cable or when (i) surrounding WiFis are off, (ii) use very different
channels, (iii) we use 5 GHz-only Wifi which is much less crowded (many people
still use 2.4 GHz, so less channel overlap). See `README_wifi.md` for more
details.

So .. with a bad Wifi setup, using an Ethernet cable is better .. and one could
just as well use a 3.5 mm audio cable instead, right? Sure, but it wouldn't be
as cool!
