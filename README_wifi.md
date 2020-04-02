Starting from cable settings:

    remote_opts="-R"
    local_opts="-R -S"
    remote_driver_opts="--nperiods 2 --period 512"
    local_driver_opts="-l1"

`local_driver_opts`: `-l`

* values &gt;&gt; 1 (e.g. 10) lead to distortions. Best setting seems
  to be 1.

`remote_driver_opts`: `--period`

* small (128) -> distortions
* large (4096)
  * either good sound for some minutes, but then broken connection
  * distortions right away

`remote_driver_opts`: `--nperiods`

* large (50) -> no effect

`remote_opts`, `local_opts`

* `-r` (no realtime) for both instead of `-R`/`-R -S` (realtime and
  sync) -> no effect observed but that *has* to be better, TODO:
  check again when many other Wifis are active
