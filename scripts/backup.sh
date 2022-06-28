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
## Create a borg archive with the given name and of the given directory
##
## # Arguments
## 1. The name of the archive
## 2. The directory to archive
###
backup() {
    borg create --compression zstd,16 --list -s @backupDirectory@/minecraft::$1 $2
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
for i in $(seq 5 -1 2); do
    announce "Server backup in $i minutes."
    sleep 60
done
announce "Server backup in 1 minute."
sleep 30
announce "Server backup in 30 seconds."
sleep 30
announce "Server backup starting, there may be some lag."

###
## Perform the backup
###
# Reset the timer
SECONDS=0
# First save everything, then turn off chunk saving
mcrcon "save-off"
mcrcon "save-all flush"

# Sleep 3 seconds and run a sync just to make sure everything gets written, we don't want any of
# those pesky "modified while backing up" errors
sleep 3
sync

timestamp=$(date "+%Y%m%d-%H%M%S")
# Backup the world
backup "world-$timestamp" /var/minecraft/world
# Backup the server files
backup "server-$timestamp" /var/minecraft/server

# After we are done with the backup, turn saving back on
mcrcon "save-on"
# Tell the players that we are done
secs=$SECONDS
# Formatting
if [ $secs -ge 60 ]; then
    announce "Server backup completed in $(printf '%dm:%ds' $((secs%3600/60)) $((secs%60)))."
else
    announce "Server backup completed in $(printf '%ds' $((secs%60)))."
fi
announce "Uploading backup.";

###
## Copy our backup to backblaze, if enabled
###

if @b2Enable@; then
    # Reset the seconds timer
    SECONDS=0
    # Update the rlone configuraion
    mkdir -p ~/.config/rclone
    [ -f ~/.config/rclone/rclone.conf  ] && rm ~/.config/rclone/rclone.conf
    cat <<EOF > ~/.config/rclone/rclone.conf
[b2]
    type = b2
    account = @b2AccountID@
    key = $(cat @b2KeyFile@)
EOF
    # Make the backup
    rclone copy @backupDirectory@ b2:@b2Bucket@/ -P --transfers 16
    # Report on the upload status
    secs=$SECONDS
    # Formatting
    if [ $secs -ge 60 ]; then
        announce "Server backup uploaded in $(printf '%dm:%ds' $((secs%3600/60)) $((secs%60)))."
    else
        announce "Server backup uploaded in $(printf '%ds' $((secs%60)))."
    fi

fi
