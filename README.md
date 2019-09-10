# Storj
My scripts for Storj SNO's

<b>Storj3Monitor</b>
this script gathers, aggregate displays and monitor all you node thresholds
if uptime or audit down by [threshold] script send email to you
  

![Alt text](https://user-images.githubusercontent.com/38987544/64577594-8a8b3200-d385-11e9-82c3-03e38e1ee92d.png?raw=true "Title")

If something wrong with your nodes you can receive messages like this:

Disconnected from node 1...w<br/>
Node 1...U down audit from 1 to 0,2 on 118<br/>
Node 1...U down uptime from 1 to 0,6 on 12L9<br/>
!WARNING! NEW WALLET 0x...<br/>


<h2>Install on Linux</h2>

<h3>0. Check if powershell already installed</h3>
run 'pwsh' or 'powershell' command

<h3>1. Install powershell.core</h3>
https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-6
<br/>
https://github.com/PowerShell/PowerShell

<h3>2. Download script</h3>
<code>
mkdir /etc/scripts/storj
cd /etc/scripts/storj<br/>
curl -O https://raw.githubusercontent.com/Krey81/Storj/master/Storj3Monitor/Storj3Monitor.ps1<br/>
</code>

<h3>3. First run</h3>
<code>pwsh ./Storj3Monitor.ps1</code>

script run with default config
you can ask default config with pwsh ./Storj3Monitor.ps1 example

<pre>
{
  "Threshold": 0.2,
  "Mail": {
    "MailAgent": "none"
  },
  "WaitSeconds": 300,
  "Nodes": "127.0.0.1:14002"
}
</pre>

<h3>4. Create config</h3>
Look examples at https://github.com/Krey81/Storj/tree/master/Storj3Monitor/ConfigSamples <br/>

<ul>
  <li><b>Storj3Monitor-builtinMail.conf</b></li>
  Send with powershell built-in mailer. You password in script config file.
  <li><b>Storj3Monitor-linuxMail.conf</b></li>
  Send with linux mail command. You password somethere in linux configs.
  <li><b>Send with google</b> (https://support.google.com/a/answer/176600)
    <i>google and other public providers not very reliable. I advise you to avoid them</i>
    <ul>
      <li>Storj3Monitor-google-to-other.conf (column 2)</li>  
      <li>Storj3Monitor-google-to-google.conf (column 3)</li>  
    </ul>
  </li>
</ul>

Make your own config. Specify nodes and mailer configuration. <br/>
So you create /etc/scripts/storj/Storj3Monitor.my.conf

<h3>5. Try run with config</h3>
<code>pwsh ./Storj3Monitor.ps1 -c /etc/scripts/storj/Storj3Monitor.my.conf</code>
check output. You must see all you nodes thresholds. 

<h3>6. Check mailer</h3>
<code>pwsh ./Storj3Monitor.ps1 -c /etc/scripts/storj/Storj3Monitor.my.conf testmail</code>
check you inbox and spam folders.

<h3>7. Setup service</h3>
Create systemd service. See https://github.com/Krey81/Storj/blob/master/Storj3Monitor/Storj3Monitor.service

<pre>
[Unit]
Description=Storj v3 monitor by Krey
Requires=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/pwsh /etc/scripts/storj/Storj3Monitor.ps1 -c /etc/scripts/storj/Storj3Monitor.my.conf monitor
ExecStop=/bin/kill --signal SIGINT ${MAINPID}

[Install]
WantedBy=multi-user.target
</pre>

<h3>8. Enable service </h3>
<code>systemctl enable Storj3Monitor.service</code>

<h3>9. Reboot and check</h3>
<code>systemctl status Storj3Monitor</code>
will be <Active: active (running)>
