About
=====

Control a realtime netjack2_ connection between two machines.

Usage
=====

Use the ``jackpod`` command to set up a netjack2_ connection (``jackpod
-rj``) and optionally start a pulseaudio sink (``jackpod -sp``, see ``pactl
list sinks``). See ``jackpod -h`` and ``README_jack.rst`` for details.

The sound flow is either (no pulse sink):

    app (``mpv --ao=jack``) -> jackd (slave) -- LAN --> jackd (master) -> sound card

or with the pulse sink ``jack_out``:

    app (``mpv --audio-device=pulse/jack_out``, browser, ...) -> pulseaudio ->
    jackd (slave) -- LAN --> jackd (master) -> sound card

For sound sources that cannot select the backend they play on (such as the
browser, and unlike ``mpv`` which can do that), use pulseaudio's
``pavucontrol`` tool to redirect sound to the sink called "Jack sink
(PulseAudio JACK Sink)", which is the ``jack_out`` sink created with ``jackpod
-sp``.

Latency & defaults
==================

We hard-coded some values such as

* the master's sound card -- in our case a Raspberri Pi with a `Hifiberry DAC
  <hfb_>`_
* values which influence the latency

so YMMV. Please just hack the values to fit your setup.

Note that netjack2 is designed to be run over a stable cable connection. We
achieve very low latency with no perceptible AV (audio-video) delay in this
case -- important for video! There is the ``-w`` (WiFi mode) option which sets
slightly more loose options which increase the AV-delay a bit. This will need to
be adjusted for your network. So far, we had stable and reliable connections
only via cable or when surrounding WiFis are either off or use very different
channels. So one could just as well use a 3.5 mm audio cable, right? Maybe, but
it wouldn't be as cool!

.. _netjack2: https://github.com/jackaudio/jackaudio.github.com/wiki/WalkThrough_User_NetJack2
.. _hfb: https://www.hifiberry.com/shop/boards/hifiberry-dac-pro
