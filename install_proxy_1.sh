#!/data/data/com.termux/files/usr/bin/bash

# Update and upgrade packages
yes | pkg update -y && yes | pkg upgrade -y

# Install Nginx
pkg install nginx -y

# Create necessary directories
mkdir -p $PREFIX/etc/nginx/sites-enabled

# Create reverse proxy configuration
cat > $PREFIX/etc/nginx/sites-enabled/reverse-proxy.conf <<EOF
server {
    listen 8282;
    server_name _;  # Accepts requests on any IP

    location / {
        proxy_pass http://192.168.1.1:80/;
        proxy_set_header Host 192.168.1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # Fix redirects from backend dynamically
        proxy_redirect http://192.168.1.1/ http://\$host:8282/;

        # Replace hardcoded URLs inside HTML responses dynamically
        sub_filter 'href="http://192.168.1.1/' 'href="http://\$host:8282/';
        sub_filter 'src="http://192.168.1.1/' 'src="http://\$host:8282/';
        sub_filter_once off;
    }
}
EOF

# Modify Nginx configuration
sed -i '/http {/a \    server_names_hash_bucket_size 64;' $PREFIX/etc/nginx/nginx.conf

# Ensure the sites-enabled directory is included
grep -q "include $PREFIX/etc/nginx/sites-enabled/*;" $PREFIX/etc/nginx/nginx.conf || \
sed -i '/http *{/a\    include '"$PREFIX"'/etc/nginx/sites-enabled/*;' $PREFIX/etc/nginx/nginx.conf

# Restart Nginx
pkill nginx
nginx
