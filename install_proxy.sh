#!/data/data/com.termux/files/usr/bin/bash


yes | pkg update -y && yes | pkg upgrade -y

pkg install nginx -y


mkdir -p $PREFIX/etc/nginx/sites-enabled

cat > $PREFIX/etc/nginx/sites-enabled/reverse-proxy.conf <<EOF
server {
    listen 8000;
    server_name 10.10.10.132;

    location / {
        proxy_pass http://192.168.200.1:80/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # Fix incorrect redirects from backend
        proxy_redirect http://10.10.10.132/ http://192.168.200.1/;
    }
}
EOF

sed -i '/http {/a \    server_names_hash_bucket_size 64;' $PREFIX/etc/nginx/nginx.conf

grep -q "include $PREFIX/etc/nginx/sites-enabled/*;" $PREFIX/etc/nginx/nginx.conf || \
sed -i '/http *{/a\    include '"$PREFIX"'/etc/nginx/sites-enabled/*;' $PREFIX/etc/nginx/nginx.conf


nginx -s stop


nginx
