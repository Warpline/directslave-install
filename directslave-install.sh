#!/bin/bash
set -e

# @author jordavin,phillcoxon,mantas15
# @updated by Afrizal-id
# @Forked and updated by Warpline.
# @date 13.08.2023
# @version 1.1.0 (for AlmaLinux 8)
# ------------------------------------------------------------------------------

# DirectSlave download link
DIRECTSLAVE_LINK="https://directslave.com/download/directslave-3.4.3-advanced-all.tar.gz"

# Ensure the script is run as root
if [ "$(id -u)" = "0" ]; then
  printf "Bingo! you are root. Continue on....\n"
else
  printf "Sorry, This script must be run as root\n"
  exit 1;
fi

# Check SELinux status
selinux_status=$(getenforce)

if [ "$selinux_status" != "Disabled" ]; then
  echo "SELinux is currently $selinux_status. Please disable SELinux in /etc/selinux/config and run the script again."
  exit 1
fi

# Check the distribution version
printf "Checking distro..." 2>&1
OS=$(cat /etc/redhat-release | awk '{print $1}')
if [ "$OS" = "AlmaLinux" ]; then
  echo "System runs on AlmaLinux 8.X. Checking Continue on....";
  VN=$(cat /etc/redhat-release | awk '{print $3}')
else
  echo "Installation failed. System runs on unsupported Linux. Exiting...";
  exit 1;
fi 

# Get user input for username and password
read -p "Enter username: " username
read -sp "Enter password: " password
echo ""

# Escape special characters in the username and password
username=$(printf '%q' "$raw_username")
password=$(printf '%q' "$raw_password")

# Function to automatically detect the public IP of the server
detect_ip() {
    # Try ipinfo.io first
    detected_ip=$(curl -s https://ipinfo.io/ip)
    if [ -z "$detected_ip" ]; then
        # If ipinfo.io fails, try icanhazip.com
        detected_ip=$(curl -s https://icanhazip.com)
    fi
    # If both services fail, return an empty string
    echo "$detected_ip"
}

# Use the function to get the detected IP
detected_ip=$(detect_ip)

# If no IP is detected after trying both services, exit the script
if [ -z "$detected_ip" ]; then
    echo "Failed to detect the server's IP. Exiting..."
    exit 1
fi

# Prompt the user for confirmation
read -p "Detected IP for this server is \"$detected_ip\". Is this correct? [Y/n]: " confirm_ip

# Confirm detected IP with the user
if [[ "$confirm_ip" =~ ^[Nn]$ ]]; then
    read -p "Enter IP you want for this server: " master_ip
else
    master_ip="$detected_ip"
fi

# Get user input for Let's Encrypt certificate details and SSH port
read -p "Enter your email (for Let's Encrypt certificate): " email
read -p "Enter your domain name (for Let's Encrypt certificate): " domain_name
# Prompt the user for the desired SSH port
read -p "Enter the desired SSH port (default is 22): " sshport
# If the user doesn't provide a port, default to 22
if [ -z "$sshport" ]; then
  sshport=22
fi

# Update SSH port in sshd_config
grep -q "^Port" /etc/ssh/sshd_config && sed -i "s/^Port.*/Port $sshport/" /etc/ssh/sshd_config || echo "Port $sshport" >> /etc/ssh/sshd_config

# Install necessary packages
echo "doing updates and installs"
dnf update -y | tee -a /root/install.log
dnf install epel-release -y | tee -a /root/install.log
dnf install bind bind-utils tar wget  -y | tee -a /root/install.log
dnf install certbot -y | tee -a /root/install.log

# Set up and start firewalld
echo "Adding simple firewalld and opening required firewalld ports..."
dnf install firewalld -y | tee -a /root/install.log
systemctl enable firewalld | tee -a /root/install.log
systemctl start firewalld | tee -a /root/install.log
firewall-cmd --permanent --add-port=${sshport}/tcp
firewall-cmd --permanent --add-service=dns
firewall-cmd --permanent --add-port=2222/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

# Generate Let's Encrypt certificate
echo "Generating Let's Encrypt certificate..."
certbot certonly --standalone --agree-tos --no-eff-email --email "$email" -d "$domain_name"

# Write the directslave-certrenew.sh script to /etc/letsencrypt directory
cat > /etc/letsencrypt/directslave-certrenew.sh <<EOL
#!/bin/bash

# Get domain name and email from arguments
domain_name="\$1"
email="\$2"

# Renew the Let's Encrypt SSL certificate using Certbot
certbot renew --standalone --agree-tos --no-eff-email --email "\$email" -d "\$domain_name"

# Update the SSL certificates for DirectSlave
cp /etc/letsencrypt/live/"\$domain_name"/fullchain.pem /usr/local/directslave/ssl/
cp /etc/letsencrypt/live/"\$domain_name"/privkey.pem /usr/local/directslave/ssl/
chown named:named /usr/local/directslave/ssl/fullchain.pem
chown named:named /usr/local/directslave/ssl/privkey.pem

# Restart the DirectSlave service to apply the new certificates
systemctl restart directslave

echo "SSL certificate renewal for DirectSlave completed."
EOL

# Make the script executable
chmod +x /etc/letsencrypt/directslave-certrenew.sh

# Add a cronjob to run the renewal script every two months, passing the domain_name and email as arguments
echo "0 0 1 */2 * root /etc/letsencrypt/directslave-certrenew.sh $domain_name $email" >> /etc/crontab

# Install and configure DirectSlave
echo "installing and configuring directslave"
cd ~
wget -q "$DIRECTSLAVE_LINK" | tee -a /root/install.log
tar -xf directslave-3.4.3-advanced-all.tar.gz
mv directslave /usr/local/
cd /usr/local/directslave/bin
mv directslave-linux-amd64 directslave
cd /usr/local/directslave/
chown named:named -R /usr/local/directslave

# Set up SSL for DirectSlave using Let's Encrypt certificates
mkdir -p /usr/local/directslave/ssl
cp /etc/letsencrypt/live/"$domain_name"/fullchain.pem /usr/local/directslave/ssl/
cp /etc/letsencrypt/live/"$domain_name"/privkey.pem /usr/local/directslave/ssl/
chown named:named /usr/local/directslave/ssl/fullchain.pem
chown named:named /usr/local/directslave/ssl/privkey.pem

# Generate a random secure key for cookie_auth_key
COOKIE_AUTH_KEY=$(openssl rand -base64 32)

# Configure DirectSlave
curip="$( hostname -I|awk '{print $1}' )"
cat > /usr/local/directslave/etc/directslave.conf <<EOF
background	1
host            $curip
sslport         2222
port            2224
ssl             on
ssl_cert        /usr/local/directslave/ssl/fullchain.pem
ssl_key         /usr/local/directslave/ssl/privkey.pem
cookie_sess_id  DS_SESSID
cookie_auth_key $COOKIE_AUTH_KEY
debug           0
uid             25
gid             25
pid             /usr/local/directslave/run/directslave.pid
access_log	/usr/local/directslave/log/access.log
error_log	/usr/local/directslave/log/error.log
action_log	/usr/local/directslave/log/action.log
named_workdir   /etc/namedb/secondary
named_conf	/etc/namedb/directslave.inc
retry_time	1200
rndc_path	/usr/sbin/rndc
named_format    text
authfile        /usr/local/directslave/etc/passwd
EOF

# Set up named (BIND) configuration
mkdir -p /etc/namedb/secondary
touch /etc/namedb/secondary/named.conf
touch /etc/namedb/directslave.inc
chown named:named -R /etc/namedb
mkdir /var/log/named
touch /var/log/named/security.log
chmod a+w -R /var/log/named

cat > /etc/named.conf <<EOF
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
// See the BIND Administrator's Reference Manual (ARM) for details about the
// configuration located in /usr/share/doc/bind-{version}/Bv9ARM.html
options {
	listen-on port 53 { any; };
	listen-on-v6 port 53 { none; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	recursing-file  "/var/named/data/named.recursing";
	secroots-file   "/var/named/data/named.secroots";
		allow-query     { any; };
		allow-notify	{ $master_ip; };
		allow-transfer	{ $master_ip; };

	/*
	 - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
	 - If you are building a RECURSIVE (caching) DNS server, you need to enable
	   recursion.
	 - If your recursive DNS server has a public IP address, you MUST enable access
	   control to limit queries to your legitimate users. Failing to do so will
	   cause your server to become part of large scale DNS amplification
	   attacks. Implementing BCP38 within your network would greatly
	   reduce such attack surface
	*/
	recursion no;
	dnssec-enable yes;
	dnssec-validation yes;
	/* Path to ISC DLV key */
	bindkeys-file "/etc/named.iscdlv.key";
	managed-keys-directory "/var/named/dynamic";
	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
zone "." IN {
	type hint;
	file "named.ca";
};
include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
include "/etc/namedb/directslave.inc";
EOF

# Set DirectSlave password and check its configuration
touch /usr/local/directslave/etc/passwd
chown named:named /usr/local/directslave/etc/passwd
/usr/local/directslave/bin/directslave --password "$username:$password"
/usr/local/directslave/bin/directslave --check | tee -a /root/install.log

# Create DirectSlave systemd service
cat > /etc/systemd/system/directslave.service <<EOL
[Unit]
Description=DirectSlave for DirectAdmin
After=network.target
[Service]
Type=simple
User=named
ExecStart=/usr/local/directslave/bin/directslave --run
Restart=always
[Install]
WantedBy=multi-user.target
EOL

# Enable and start services
echo "setting enabled and starting up"
chown root:root /etc/systemd/system/directslave.service
chmod 755 /etc/systemd/system/directslave.service
systemctl daemon-reload | tee -a /root/install.log
systemctl enable named | tee -a /root/install.log
systemctl enable directslave | tee -a /root/install.log
systemctl restart named | tee -a /root/install.log
systemctl restart directslave | tee -a /root/install.log

# Check DirectSlave and start it
echo "Checking DirectSlave and starting"
/usr/local/directslave/bin/directslave --check
/usr/local/directslave/bin/directslave --run

# Test SSH configuration
sshd -t
if [ $? -ne 0 ]; then
    echo "Error in SSH configuration. Please check /etc/ssh/sshd_config."
    exit 1
fi

# Restart SSH service
systemctl restart sshd

# Completion message
echo "all done!"
echo "Open the DirectSlave Dashboard using a web browser https://"$domain_name":2222"
exit 0;
