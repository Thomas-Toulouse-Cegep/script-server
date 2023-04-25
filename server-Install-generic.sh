#!/bash/sh
# note le script doit être lancé avec sudo
# This script is used to install the server
# init the server base
set -e   #Exit immediately if a command exits with a non-zero status

# Configuration
SERVER_NAME="example.com"
sudo apt update && sudo apt upgrade -y
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get install -y apt-transport-https
sudo apt update
sudo apt-get install -y net-tools openssh-server dotnet-sdk-6.0 nginx vsftpd

# config file vsftpd
sudo touch /etc/vsftpd
# Configure vsftpd
sudo tee /etc/vsftpd.conf > /dev/null <<EOF
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=Yes
pasv_enable=Yes
pasv_min_port=10000
pasv_max_port=10100
allow_writeable_chroot=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
EOF
sudo systemctl enable vsftpd.service
sudo systemctl start vsftpd.service

# Create web folders
sudo mkdir -p /var/www/react-app /var/www/api
# config file nginx
sudo tee /etc/nginx/sites-enabled/default > /dev/null <<EOF
server {
  listen 80;
  listen [::]:80;
  server_name ${SERVER_NAME};

  location / {
    root /var/www/react-app;
    index index.html index.htm;
    try_files \$uri \$uri/ =404;
  }

  location /api {
    proxy_pass         http://127.0.0.1:5000;
    proxy_http_version 1.1;
    proxy_set_header   Upgrade \$http_upgrade;
    proxy_set_header   Connection keep-alive;
    proxy_set_header   Host \$host;
    proxy_cache_bypass \$http_upgrade;
    proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto \$scheme;
  }
}
EOF
sudo systemctl restart nginx
