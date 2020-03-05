<h1>Storj3Updater</h1>

This script is designed to update the storagenode binary file from two sources
1. From links provided by version.storj.io
2. From docker images on hub.docker.com

At the time when this script wrote, there are two methods of automatic updating from storjlabs - for windows, based on links provided by version.storj.io and docker images on docker hub.
Thus, this script is intended mainly for those who run nodes under Linux but without docker
Script have systemd integration for stop/start systemd storagenode services during update procedure

usage:
storj3updater version
storj3updater download -m [auto|docker|native]
storj3updater update -m [auto|docker|native]

For automatic updates set systemd_integration to true, check service_pattern and add command to cron
cron line example for every hour updates:
15 * * * * /usr/bin/pwsh /etc/scripts/Storj3Updater.ps1 update 2>&1 >>/var/log/storj/updater.log
- Be sure to change 15 minutes to something else so as not to create peak loads on the update servers
