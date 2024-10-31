#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install NGINX
sudo apt install nginx -y

# Install MariaDB
sudo apt install mariadb-server mariadb-client -y

# Install PHP-FPM and required modules
sudo apt install php-fpm php-mysql php-mbstring php-zip php-gd php-json php-curl -y

# Install phpMyAdmin
sudo apt install phpmyadmin -y

# Create NGINX configuration for phpMyAdmin
cat > /etc/nginx/conf.d/phpmyadmin.conf << EOF
server {
    listen 80;
    server_name localhost;

    root /usr/share/phpmyadmin;
    index index.php index.html index.htm;

    # PHP-FPM Configuration
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Deny access to sensitive files
    location ~ ^/(.git|config|tmp|temp|libraries) {
        deny all;
        return 404;
    }

    # Additional security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
}
EOF

# Create MariaDB security script
cat > ~/mysql_secure_installation.sql << EOF
-- Delete anonymous users
DELETE FROM mysql.user WHERE User='';
-- Disable remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- Reload privilege tables
FLUSH PRIVILEGES;
EOF

# Optimize PHP-FPM configuration
cat > /etc/php/php-fpm.d/custom.conf << EOF
[global]
pid = /run/php-fpm/php-fpm.pid
error_log = /var/log/php-fpm/error.log
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s

[www]
user = www-data
group = www-data
listen = /var/run/php/php-fpm.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
EOF

# Secure installation
sudo mysql_secure_installation

# Create admin user
sudo mysql -u root -p
