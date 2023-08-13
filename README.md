# directslave-install

**Install DirectSlave version 3.4.3 with SSL support** for DirectAdmin control panel on AlmaLinux 8 64-bit as a free DNS Cluster solution. This version introduces enhanced security with Let's Encrypt SSL integration and improved user experience.

## Objective
- Running DirectSlave as a secondary DNS Cluster for the DirectAdmin control panel with SSL support.
- Maintain updated documentation/tutorials on installation & configuration of DirectSlave GO Advanced.

## Installing
1. Make the script executable:
```bash
chmod +x directslave-install.sh
```
2. Run the script. It will prompt you for the necessary details:
```bash
./directslave-install.sh
```
You will be prompted for:
- Username and password for DirectSlave.
- Email and domain name for Let's Encrypt certificate.
- Desired SSH port (default is 22).

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
- **SSL Support**: DirectSlave now supports SSL using Let's Encrypt certificates.
- **Automatic IP Detection**: The script automatically detects the server's IP and confirms it with the user.
- **User Prompts**: Enhanced user experience with prompts for necessary details.
- **SSH Configuration Test**: The script tests the SSH configuration to ensure it's correct.
- **Updated DirectSlave Link**: The script now installs DirectSlave version 3.4.3.
- **Root Installation Check**: Ensures the script is run as root.
- **Firewalld Integration**: Transitioned from fail2ban to Firewalld for better security.
- **SSHD Port Customization**: Allows the user to specify a custom SSH port.
- **Support for AlmaLinux 8**: Added compatibility for AlmaLinux 8.

## References
- Original script by jordivn: [DirectAdmin Forum Post](https://forum.directadmin.com/showthread.php?t=43924&page=22&p=278112#post278112)
- DirectSlave software: [Download DirectSlave](https://directslave.com/download)
- Forked, enhanced, and future updates provided by: [Warpline Hosting](https://www.warpline.com/)
