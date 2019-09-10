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


<b>Install on Linux</b>

1. Install powershell.core<br/>
https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-6
https://github.com/PowerShell/PowerShell

2. Download script
mkdir /etc/scripts/storj
cd /etc/scripts/storj
wget https://raw.githubusercontent.com/Krey81/Storj/master/Storj3Monitor/Storj3Monitor.ps1

3. First run
pwsh ./Storj3Monitor.ps1

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

4. Create config
Look examples at https://github.com/Krey81/Storj/tree/master/Storj3Monitor/ConfigSamples
Make your own config. Specify nodes and mailer configuration. 
So you create /etc/scripts/storj/Storj3Monitor.my.conf






