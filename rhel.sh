#!/bin/bash

# Step 1: Get hostname from user
read -r -p "Enter hostname: " hostname

# Step 2: Get PHP version from user
read -r -p "Enter PHP version (e.g., 7.2 or 8.3): " php_version

# Step 3: Get MariaDB version from user
read -r -p "Enter MariaDB version (e.g., 10.3 or 11.4): " mariadb_version

# Step 4: Get Email address for certbot
read -r -p "Enter your Email : " EMAIL

# Build packages for first time
sudo yum update -y
sudo yum install -y git wget curl zip unzip

# Step 5: Update system and install Nginx
echo "Updating system and installing Nginx..."
sudo yum install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Step 6: Install PHP with the specified version
echo "Installing PHP $php_version..."
sudo yum install -y epel-release
sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo yum module reset php -y
sudo yum module enable php:remi-$php_version -y
sudo yum install -y php php-fpm php-curl php-json php-xml php-xmlrpc php-gd php-intl php-soap

# Step 7: Install MariaDB with the specified version
echo "Installing MariaDB $mariadb_version..."
sudo curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=$mariadb_version
sudo yum install -y MariaDB-server MariaDB-client
sudo systemctl enable mariadb
sudo systemctl start mariadb
mysql_secure_installation --use-default

# Step 8: Create Nginx configuration file
config_file="/etc/nginx/conf.d/${hostname}.conf"
echo "Creating Nginx configuration at $config_file..."
sudo mkdir -p /var/www/$hostname
sudo bash -c "cat > $config_file" <<EOL
server {
    listen 80;
    server_name $hostname;
    charset utf-8;
    root /var/www/$hostname;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi.conf;
    }

    # Security configurations
    location ~ /\.ht {deny all;}
    location ~ /\.svn/  {deny all;}
    location ~ /\.git/  {deny all;}
    location ~ /\.hg/   {deny all;}
    location ~ /\.bzr/  {deny all;}

    # Deny access to sensitive files and directories
    location ~* "(base64_encode|eval|etc/passwd|shell|config|settings)\.php" {
        deny all;
    }
}
EOL

# Restart Nginx to apply changes
echo "Restarting Nginx..."
sudo systemctl restart nginx

# Install SSL certifications
echo "Install SSL/TLS Certifications ..."
echo " Stay Halal and say hello to VAHID Iranpour on Community.vahid@hotmail.com"
sudo yum install -y certbot python3-certbot-nginx
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
certbot --nginx --agree-tos --email $EMAIL -d $hostname

echo "Setup complete!"
echo "Please put your files into /var/www/$hostname"