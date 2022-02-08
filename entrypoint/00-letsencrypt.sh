#!/bin/sh
# vim:sw=2:ts=2:sts=2:et

# lets encrypt --------------------------------------
## generate 2048 dh parameters
  if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 
  fi

## create directories (irrelevant if already exists)
  mkdir -p /var/lib/letsencrypt/.well-known
  chgrp www-data /var/lib/letsencrypt
  chmod g+s /var/lib/letsencrypt 

## create deploy hook to auto reload nginx when new certs renew
  if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
    echo "deploy-hook = systemctl reload nginx" > /etc/letsencrypt/cli.ini
  fi
update-ca-certificates

# clean sites-enabled, as sites will be managed from conf.d (30-<domain>.conf) mapped from docker
  rm -rf /etc/nginx/sites-enabled/*

# add default site landing config
  if [ ! -f "/etc/nginx/conf.d/20-default.conf" ]; then
    tee /etc/nginx/conf.d/20-default.conf<<'EOF'
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  root /var/www/html;
  index index.html index.htm index.nginx-debian.html;
  server_name _;
  location / {
          # First attempt to serve request as file, then
          # as directory, then fall back to displaying a 404.
          try_files $uri $uri/ =404;
  }
}
EOF
  fi