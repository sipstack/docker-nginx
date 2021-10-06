# docker-nginx

Dockerized NGINX with Letsencrypt bundled

## Usage

### Deploy with docker run

```
docker run -d --name nginx -p 80:80 -p 443:443 -v /srv/nginx/log:/var/log/nginx -v /srv/nginx/conf.d:/etc/nginx/conf.d -v /srv/nginx/html:/var/www/html -v /srv/nginx/letsencrypt:/etc/letsencrypt sipstack/nginx
```

### Deploy with docker compose

```
version: "2.1"
services:
  nginx:
    image: sipstack/nginx
    container_name: nginx
    cap_add:
      - NET_ADMIN
    environment:
      - TZ=America/Toronto
    volumes:
      - /srv/nginx/log/:/var/log/nginx
      - /srv/nginx/conf.d/:/etc/nginx/conf.d
      - /srv/nginx/html:/var/www/html
      - /srv/nginx/letsencrypt:/etc/letsencrypt
    ports:
      - 443:443
      - 80:80
    restart: unless-stopped
```

## Letsencrypt Guide

### Add new certificate / to chain

```
docker exec -it nginx certbot certonly --agree-tos --email webmaster@example.com --webroot -w /var/lib/letsencrypt/ -d example.com -d www.example.com
```

### Renew

```
docker exec -it nginx certbot renew --dry-run
```

### Delete

```
docker exec -it nginx certbot delete --cert-name example.com
```

## Nginx Guide

### Usage

```
# test config
docker exec -it nginx nginx -t

# reload config
docker exec -it nginx service nginx reload

# restart nginx
docker exec -it nginx service nginx restart
```

### Examples

These configuration files should be stored in **/srv/nginx/conf.d/30-example_www.conf**

#### HTTP

```
server {
  listen 80;
  server_name example.com www.example.com;
  include snippets/letsencrypt.conf;
  include snippets/proxy.conf;
}
```

#### HTTPS

```
server {
    listen 80;
    server_name www.example.com example.com;

    include snippets/letsencrypt.conf;
    include snippets/force-ssl.conf;
}

server {
    listen 443 ssl http2;
    server_name www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    return 301 https://example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    # . . . other code
}
```
