<h1>Storj3Updater</h1>

This script is designed to update the storagenode binary file from two sources
1. From links provided by version.storj.io
2. From docker images on hub.docker.com

At the time when this script wrote, there are two methods of automatic updating from storjlabs - for windows, based on links provided by version.storj.io and docker images on docker hub.<br/>
Thus, this script is intended mainly for those who run nodes under Linux but without docker <br/>
Script have systemd integration for stop/start systemd storagenode services during update procedure <br/>

<pre>
usage:
storj3updater version
storj3updater download -m [auto|docker|native]
storj3updater update -m [auto|docker|native]

For automatic updates set systemd_integration to true, check service_pattern and add command to cron
cron line example for every hour updates:
15 * * * * /usr/bin/pwsh /etc/scripts/Storj3Updater.ps1 update 2>&1 >>/var/log/storj/updater.log
- Be sure to change 15 minutes to something else so as not to create peak loads on the update servers
</pre>

<h2>Node with updater setup instruction - Linux</h2>

1. Install powershell https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7<br/> 
2. Download this script 
<pre> 
curl -OL https://github.com/Krey81/Storj/raw/master/Storj3Updater/storj3updater.ps1 
</pre>
3. Enable systemd integration in script
<pre>
nano storj3updater
find line systemd_integration = $false and change $false to $true
</pre> 
4. Download storj binary 
<pre> 
#pwsh may be pwsh-preview depending of installed powershell version
pwsh ./storj3updater.ps1 download
mv ./storagenode /usr/sbin/
</pre> 
5. Create systemd service file per node 
<pre> 
nano /etc/systemd/system/storj-node02.service (change 02 to you node number) 
insert lines, edit paths

[Unit]
Description=Storagenode-02 service
Requires=network.target
After=network-online.target
Wants=network-online.target
ConditionPathExists=/mnt/storj/node02/storage

[Service]
Type=simple
ExecStart=/usr/sbin/storagenode run --identity-dir /mnt/storj/node02/identity --config-dir /mnt/storj/node02 --log.output /var/log/storj/node02.log
TimeoutStopSec=600
Restart=always

[Install]
WantedBy=multi-user.target
</pre>
6. Enable and start service, ensure service active
<pre>
systemctl enable storj-node02
systemctl start storj-node02
systemctl status storj-node02
</pre>

7. Add updater to cron
<pre>
crontab -e
add line
15 * * * * /usr/bin/pwsh /etc/scripts/storj3updater.ps1 update 2>&1 >>/var/log/storj/updater.log

change 15 to current time minutes+5
edit path to updater script
edit path to updater log
</pre>

8. Check updater log
<pre>
tail -f /var/log/storj/updater.log
</pre>
