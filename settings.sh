# The options here are meant to be changed for minimizing latency issues. The
# only preset we have is wifi_mode, which works more or less, but will need
# tuning for other networks. All other master and slave netjack2 related
# options are hard-coded in the functions used in the main script.
set_opts(){
    local wifi_mode=$1
    if $wifi_mode; then
        remote_opts="-r"
        local_opts="-r"
        remote_driver_opts="--nperiods 2 --period 1024"
        local_driver_opts="-l1"
    else
        remote_opts="-R"
        local_opts="-S -R"
        remote_driver_opts="--nperiods 2 --period 512"
        local_driver_opts="-l1"
    fi
}

log_fn=/tmp/jack.log
# send stderr and stdout into the wild blue yonder, will be replaced with
# $log_fn when debug=true
log=/dev/null

# Hard-code the remote (master) hostname and our soundcard over there. If
# needed, add CLI flags for that or a config file, but .. really just hack
# these two lines.
remote=raspi
remote_device="hw:sndrpihifiberry"

# To avoid awkward gymnastics in checkopt ($# changes if any of the input args
# is an empty string), we define a None/null/nil value here that is not the
# empty string. Yes this tool should be written in another language.
none="::"

# B/c of quoting foo, use
#   eval $ssh_cmd [rest of ssh cmd line]
ssh_cmd="ssh -o ConnectTimeout=2 -T $remote"
