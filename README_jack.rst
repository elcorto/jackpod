Overview
========

In netJACK we start a ``jackd`` on each machine, one in master and one in slave
mode.

master: remote machine, sound target (a Raspberri Pi on our case, with amp and
boxes attached to a Hifiberry DAC sound card)::

    $ jackd -R ...
    $ jack_load netmanager -i -c

slave: local machine, sound source ("slavebox")::

    $ jackd -S -R -d net ...

jackd documentation glitches
============================

* ``-S/--sync`` only in ``jackd -h``
* ``-S`` in the man page is something else than ``--sync``
* ``-Z/--nozombies`` in man page, but doesn't exist
* ``-t/--transport_sync`` in man page but not in ``jackd -d net -h``, also ignored, it
  was disabled in netjack2 (search github issues for details)
* ``-d net`` backend options not in man page, only ``jackd -d net -h``

jackd vs jack_control
=====================

The JACK2 distribution consists of

* ``jackd`` - server CLI, for master and slave
* ``jack_control`` - alternative CLI written in Python, uses ``dbus`` and talks
  to ``jackdbus``, alternative to using ``jackd``, use only one of them
* ``jackdbus`` - ``dbus`` interface, started when ``jack_control`` is used AFAIK
* ``jack_*`` - ELF binaries (``jack_connect``, ``jack_lsp``, ...)

``jack_control`` .. don't use it. It is funnily coded Python and rather slow. But
more importantly, the ``dbus`` connection sucks. Especially on RuneAudio (Arch,
headless) it was a big PITA (see below). Just use the ``jackd`` cmd line and
the ``jack_*`` tools. ``jackd`` starts *much* faster and has the same settings.

Test slave's Jack setup
=======================

Debian client machine (slavebox)::

    $ sudo apt install jackd2 qjackctl pulseaudio-module-jack

Start server::

    $ jackd -d alsa

It is important to specify the driver (``-d`` option). With the default
``dummy`` driver, there is no sound.

List ports::

    $ jack_lsp
    system:capture_1
    system:capture_2
    system:playback_1
    system:playback_2

Monitor connections between ports (click "Connect" button)::

    $ qjackctl &

Play test sound::

    $ jack_simple_client

``jackd`` will use the specified driver (alsa) and play thru the
``system:playback_*`` ports on the default sound card, which works out of the
box if you have only one. More on multiple sound cards below.

Play some music, sending to ``jackd`` directly::

    $ mpv --ao=jack foo.mp3
    $ mpv --audio-device=jack foo.mp3

mpv creates ports ``mpv:out_* --> system:playback_*`` while it runs::

    $ jack_lsp
    system:capture_1
    system:capture_2
    system:playback_1
    system:playback_2
    mpv:out_0
    mpv:out_1

Now we create a PulseAudio sink which feeds to jack::

    $ pactl load-module module-jack-sink

    $ jack_lsp
    ...
    PulseAudio JACK Sink:front-left
    PulseAudio JACK Sink:front-right

    $ pactl list sinks
    Sink #6
        State: SUSPENDED
        Name: jack_out
        ...

    mpv --audio-device=pulse/jack_out foo.mp3

The sound flow is ``mpv --> PulseAudio JACK Sink --> system:playback``. We can
use this sink to play music from the browser (use ``pavucontrol`` -> select
"Jack sink (PulseAudio JACK Sink)").

Test master's Jack setup
========================

This is our Raspberri Pi.

Raspbian (headless)
-------------------

Install -- same as Debian above.

Follow https://wiki.linuxaudio.org/wiki/raspberrypi for headless stuff.

Basically, add::

    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket

and fiddle with dbus permissions for sound card access::

    pi@raspberrypi:~ $ cat jackass.conf
    <?xml version="1.0"?> <!--*-nxml-*-->
    <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
            "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">

    <busconfig>

            <policy context="default">
                    <allow own="org.freedesktop.ReserveDevice1.Audio0"/>
                    <allow own="org.freedesktop.ReserveDevice1.Audio1"/>
            </policy>

    </busconfig>

    pi@raspberrypi:~ $ sudo cp jackass.conf /etc/dbus-1/system.d/
    pi@raspberrypi:~ $ sudo chmod a+r /etc/dbus-1/system.d/jackass.conf
    pi@raspberrypi:~ $ sudo systemctl restart dbus


RuneAudio, Arch Linux (headless)
--------------------------------

The RuneAudio version we use is based on Arch. It runs jackd1, a.k.a. version
0.125 (on Debian: apt install jackd1, default "jackd" is jackd2).

Update package db, install jackd2::

    root@runeaudio(rw):~# pacman -Sy
    root@runeaudio(rw):~# pacman -S jack2 glibc

``jack_lsp`` needs up-to-date glibc ...

If you want to use ``jack_control`` for some reason (there isn't any), note
that RuneAudio is headless (no X), but ``dbus`` somehow needs this (why??).
Also, you'll run into other ``dbus`` errors and need to start a new dbus
session (at least that worked for us), since the usual ``export
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket`` didn't help::

    $ export $(dbus-launch) DISPLAY=:0
    $ jack_control

But again, use the ``jackd`` CLI instead. In this case, settings
``DBUS_SESSION_BUS_ADDRESS`` as stated above should suffice (untested, we
switched to headless Raspbian instead, sorry RuneAudio).

test
----

The only difference to testing on the slave (slavebox) is that we need to
specify the sound card::

    pi@raspberrypi:~ $ cat /proc/asound/cards
     0 [ALSA           ]: bcm2835_alsa - bcm2835 ALSA
                          bcm2835 ALSA
     1 [sndrpihifiberry]: HifiberryDacp - snd_rpi_hifiberry_dacplus
                          snd_rpi_hifiberry_dacplus

I guess asound is for alsa only. Use ``hw:<stuff inside [..]>`` ::

    jackd -d alsa --device hw:sndrpihifiberry


sync and async mode in netjack2
===============================

See
https://github.com/jackaudio/jackaudio.github.com/wiki/WalkThrough_User_NetJack2
for details.

tl;dr

We want sync mode for realtime stuff.

``-S`` enables the sync mode. Verify that it works by examining the output of
``jackd -S -R -P80 -d net -l1`` at startup (client/slave)::

    jackdmp 1.9.12
    [...]
    JACK server starting in realtime mode with priority 80
    self-connect-mode is "Don't restrict self connect requests"
    NetDriver started in sync mode without Master's transport sync.
    Waiting for a master...
    Initializing connection with raspberrypi...
    **************** Network parameters ****************
    Name : slavebox
    Protocol revision : 8
    MTU : 1500
    Master name : raspberrypi
    Slave name : slavebox
    ID : 1
    Transport Sync : no
    Send channels (audio - midi) : 0 - 0
    Return channels (audio - midi) : 2 - 0
    Sample rate : 48000 frames per second
    Period size : 512 frames per period
    Network latency : 1 cycles
    SampleEncoder : Float
    Slave mode : sync
    ****************************************************

Note that "Slave mode : sync" - ok, but "NetDriver started in sync mode
without Master's transport sync." since transport sync doesn't work in
netjack2.

Traffic
=======

When the pulse sink is active, we observe a constant traffic of about 420 KiB
slave -> master (using the default sample rate of 48 kHz), no matter if sound
is playing or not. If you find this annoying & you don't use the sink, then
``jackpod -kp`` and use the jack backend directly (e.g ``mpv --ao=jack``).

With only the netjack2 connection active we have about 16 KiB idle traffic (no
sound) and the same 420 KiB traffic when playing something.


Misc
====

suppress motd
-------------

::

    pi@raspberrypi$ touch .hushlogin


refs
====
https://wiki.ubuntuusers.de/netJACK/
