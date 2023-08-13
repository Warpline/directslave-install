### Changelog:

## 13.08.2023 - v1.1.0
1. **Interpreter Change**: The script now uses `#!/bin/bash` instead of `#!/bin/sh`.
2. **Error Handling**: The updated script uses `set -e` to exit immediately if a command exits with a non-zero status.
3. **DirectSlave Link Update**: The download link for DirectSlave has been updated to version `3.4.3`.
4. **Distribution Check**: The script now checks for `AlmaLinux` instead of `CentOS`.
5. **User Input**: The updated script prompts the user for the username, password, email, domain name, and SSH port. Special characters in the username and password are escaped.
6. **IP Detection**: The script now automatically detects the public IP of the server using `ipinfo.io` and `icanhazip.com`.
7. **Let's Encrypt Integration**: The updated script installs `certbot` and generates a Let's Encrypt certificate for the provided domain.
8. **DirectSlave SSL Setup**: The script sets up SSL for DirectSlave using the generated Let's Encrypt certificates.
9. **DirectSlave Configuration**: The configuration for DirectSlave has been updated to include SSL settings.
10. **Firewalld Setup**: The script now also opens port `80` (HTTP) in the firewall for future certificate renewals using certbot.
11. **SSH Configuration Test**: The script tests the SSH configuration using `sshd -t` and provides an error message if there's an issue.
12. **Completion Message**: The completion message now provides an HTTPS link to the DirectSlave Dashboard using the provided domain name.
13. **Various Code Refinements**:
   - Use of `dnf` instead of `yum`.
   - Improved logging with `tee -a /root/install.log`.
   - Removed redundant code and improved code structure for clarity.

These changes reflect the evolution of the script to support AlmaLinux, enhanced security with SSL, better user experience with prompts, and overall improvements in code quality and structure.
