#!/usr/bin/env bash

###
## Turn on guard rails
###
set -euxo pipefail

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
    mcrcon -p $(cat @rconPasswordFile@) "tellraw @a [\"\",{\"text\":\"[\",\"bold\":true,\"color\":\"red\"}\
        ,{\"text\":\"ANN\",\"bold\":true,\"color\":\"dark_red\"},{\"text\":\"]\",\"bold\":true,\
        \"color\":\"red\"},{\"text\":\" - \",\"bold\":true,\"color\":\"dark_gray\"},{\"text\":\
        \"$1\",\"underlined\":true,\"color\":\"gold\"}]"
}

###
## Directory Setup
###
# make sure backup directory exists
mkdir -p @backupDirectory@
# Test for the existence of our repo
if [[ ! -d @backupDirectory@/minecraft ]]; then
    borg init --encryption=none @backupDirectory@/minecraft
fi

# Make some announcments and wait
announce "Server backup in 5 minutes, there may be some lag."
sleep 1
for i in $(seq 4 -1 2); do
    announce "Server backup in $i minutes."
    sleep 1
done
announce "Server backup in 1 minute."
sleep 1
announce "Server backup in 30 seconds, prepare for lag."
sleep 1
announce "Server backup started, the lag commences."

###
## Perform the backup
###
# First save everything, then turn off chunk saving
mcrcon -p $(cat @rconPasswordFile@) "save-all flush"
mcrcon -p $(cat @rconPasswordFile@) "save-off"

# Do the borg backup with the following options
borg create --compression zstd,16 --list -s @backupDirectory@/minecraft::$(date "+%Y%m%d-%H%M%S")\
    /var/minecraft/server

# After we are done with the backup, turn saving back on
mcrcon -p $(cat @rconPasswordFile@) "save-on"
# Tell the players that we are done
announce "Server backup finished, the lag should subside now."

# TODO add config to rclone the backup to backblaze b2
# TODO log and announce the ammount of time and maybe statistics?
