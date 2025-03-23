#!/data/data/com.termux/files/usr/bin/bash

# Update & Upgrade Termux Packages
echo "[+] Updating Termux packages..."
pkg update -y && pkg upgrade -y

# Install NGINX
echo "[+] Installing NGINX..."
pkg install nginx -y

# Create NGINX Reverse Proxy Config
echo "[+] Configuring NGINX Reverse Proxy..."
mkdir -p $PREFIX/etc/nginx/sites-enabled

cat > $PREFIX/etc/nginx/sites-enabled/reverse-proxy.conf <<EOF
server {
    listen 8080;
    server_name 192.168.200.100;

    location / {
        proxy_pass http://192.168.200.1:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Link configuration to main nginx.conf
echo "[+] Linking configuration..."
mkdir -p $PREFIX/var/log/nginx
sed -i '/http {/a\    include '"$PREFIX"'/etc/nginx/sites-enabled/*;' $PREFIX/etc/nginx/nginx.conf

# Check & Restart NGINX
echo "[+] Testing NGINX configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "[+] Restarting NGINX..."
    nginx
    echo "[+] Reverse Proxy Deployed Successfully!"
else
    echo "[!] Error in NGINX Configuration!"
    cat $PREFIX/var/log/nginx/error.log
fi
