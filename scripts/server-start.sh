#!/usr/bin/env bash

###
## Turn on guard rails
###
set -euxo pipefail

###
## Link a file
##
## If the destination already exists, this will delete the existing link and create a new one
##
## # Arguments
## 1. Source
## 2. Destination
###
link_file () {
    # Delete the destination if it already exists
    if [[ -f $2 ]]; then
        rm -f $2
    fi
    # Link the source to the destination
    ln -s $1 $2
}
###
## Link a directory
##
## If the destination already exists, this will delete the existing link and create a new one
##
## # Arguments
## 1. Source
## 2. Destination
###
link_dir () {
    # Delete the destination if it already exists
    if [[ -d $2 ]]; then
        rm -rf $2
    fi
    # Link the source to the destination
    ln -s $1 $2
}

###
## Wait for network online
##
## The guard rails will cause the script to fail here if the network is not yet up
###
/run/wrappers/bin/ping 8.8.8.8 -c 1 -W 0.25

###
## Directory setup
###
# Ensure that the server directory exists
mkdir -p /var/minecraft/server
# Ensure that the world directory exists, and link it in
mkdir -p /var/minecraft/world
link_dir /var/minecraft/world /var/minecraft/server/world
# Copy the properties file, removing it if it already exists
[ -f /var/minecraft/server/server.properties] && rm /var/minecraft/server/server.properties
cp @propertiesFile@ /var/minecraft/server/server.properties
# Make it writeable so we can set the rcon password
chmod u+w /var/minecraft/server/server.properties
# tack on the rcon password
echo "rcon.password=$(cat @rconPasswordFile@)" >> /var/minecraft/server/server.properties
# Link the quilt installer
link_file @quiltInstaller@ /var/minecraft/quilt-installer.jar
# Accept eula if configured to do so
echo "eula=@acceptEula@" > /var/minecraft/server/eula.txt;
# Install packwiz bootstrapper
link_file @packwizBootstrap@ /var/minecraft/server/packwiz-installer-bootstrap.jar

###
## Loader and pack installation
###
# Install quilt
cd /var/minecraft
java -jar quilt-installer.jar install server @minecraftVersion@ @quiltVersion@ --download-server
# Run packwiz to update the pack
cd server
java -jar packwiz-installer-bootstrap.jar -g -s server @packwizUrl@


###
## Start the server
###
# Time to run minecraft
java -XX:+UseShenandoahGC -Xmx@ram@M -Xms@ram@M -Xmn256M -jar quilt-server-launch.jar -nogui
