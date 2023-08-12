# directslave-install

**Install free DirectSlave version 3.4.3** for DirectAdmin control panel on AlmaLinux 8 64-bit as a free DNS Cluster solution.
Support for more operating systems will be added in future updates.

## Objective
- Running DirectSlave as a secondary DNS Cluster for the DirectAdmin control panel.
- Maintain updated documentation/tutorials on installation & configuration of DirectSlave GO Advanced.

## Installing
1. Make the script executable:
```bash
chmod +x directslave-install.sh
```
2. Run the script with the required parameters:
```bash
./directslave-install.sh (user) (passwd) (IP server DirectAdmin)
```
To customize the DirectAdmin port:
```bash
./directslave-install.sh (user) (passwd) (IP server DirectAdmin:port number)
```

## After Installation
**On the DirectSlave server**, modify `named.conf` to:

```bash
options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { none; };
    allow-query { any; };
    allow-notify { DirectAdmin_IP_server; };
    allow-transfer { DirectAdmin_IP_server; };
}
```
<br>

**On the DirectAdmin server**, update `named.conf` to:

```bash
options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { none; };
    allow-query { any; };
    allow-notify { DirectSlave_IP_server_1, DirectSlave_IP_server_2; };
    allow-transfer { DirectSlave_IP_server_1, DirectSlave_IP_server_2; };
}
```
<br>

## What's New?
- Installation of DirectSlave including version 3.4.3.<br>
- Root installation check.<br>
- Transitioned from fail2ban to Firewalld.<br>
- SSHD port updates.<br>
- Installation check.<br>
- Added support for AlmaLinux 8.

## References
- Original script by jordivn: [DirectAdmin Forum Post](https://forum.directadmin.com/showthread.php?t=43924&page=22&p=278112#post278112)
- DirectSlave software: [Download DirectSlave](https://directslave.com/download)
- Updates provided by: [Warpline Hosting](https://www.warpline.com/)
