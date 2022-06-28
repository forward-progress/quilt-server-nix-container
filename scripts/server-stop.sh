#!/usr/bin/env bash
###
## Turn on guard rails
###
set -euxo pipefail
# Load in rcon variables
export MCRCON_PORT="@rconPort@"
export MCRCON_PASS="$(cat @rconPasswordFile@)"

###
## Announce something
##
## This will issue a `tellraw` over mcrcon to send an announcement message with the baked in
## announcement formatting
##
## # Arguments
## 1. The text to format and announce
###
announce() {
    mcrcon "tellraw @a [\"\",{\"text\":\"[\",\"bold\":true,\"color\":\"red\"}\
        ,{\"text\":\"ANN\",\"bold\":true,\"color\":\"dark_red\"},{\"text\":\"]\",\"bold\":true,\
        \"color\":\"red\"},{\"text\":\" - \",\"bold\":true,\"color\":\"dark_gray\"},{\"text\":\
        \"$1\",\"underlined\":true,\"color\":\"gold\"}]"
}

###
## Get the PID of a running instance
###
get_pid() {
    ss -lpt '( sport = :@minecraftPort@ )' | rg 'pid=(\d+)' -or '$1'
}

# Check to see if the server is up, if it isn't, then do nothing
if get_pid; then
    PID=$(get_pid)
    echo $PID
    # Announce the shutdown
    announce "Server shutting down..."
    sleep 3
    # Save everything
    mcrcon "save-all flush"
    # Shutdown the server
    mcrcon "stop"
    # Wait for the server to shutdown
    # TODO Add some timeout
    SECONDS=0
    while ps -p $PID > /dev/null; do
        echo "Server still up after $SECONDS seconds"
        sleep 2
    done
    echo "Server down"
else
    echo "Server already down!"
fi
