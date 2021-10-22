#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#
FROM debian:buster-slim

LABEL maintainer="Jonathan Geller <jgeller@sipstack.com>"

ENV NGINX_EXTRAS    false

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    # && addgroup --system --gid 101 nginx \
    # && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends --no-install-suggests -y gnupg ca-certificates nano curl wget htop nginx nginx-extras certbot gettext-base iputils-ping \
    # if [ "$NGINX_EXTRAS" -eq "true" ]; then \
    #     apt-get install --no-install-recommends --no-install-suggests -y nginx-extras 
    # fi
    && apt-get remove --purge --auto-remove -y \

# lets encrypt --------------------------------------
## generate 2048 dh parameters
    && openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 \

## create directories
    && mkdir -p /var/lib/letsencrypt/.well-known \
    && chgrp www-data /var/lib/letsencrypt \
    && chmod g+s /var/lib/letsencrypt \

   && echo "deploy-hook = systemctl reload nginx" >> /etc/letsencrypt/cli.ini \

# extra
    && rm -rf /etc/nginx/sites-enabled/* \


# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \

# create a docker-entrypoint.d directory
    && mkdir /docker-entrypoint.d

COPY assets/snippets/* /etc/nginx/snippets/
COPY assets/sites-available/* /etc/nginx/sites-available/
COPY assets/docker-entrypoint.sh /
# COPY 20-envsubst-on-templates.sh /docker-entrypoint.d
COPY assets/30-tune-worker-processes.sh /docker-entrypoint.d
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80 443

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]