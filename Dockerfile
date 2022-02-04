#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#

FROM debian:bullseye-slim

LABEL maintainer="Jonathan Geller <jgeller@sipstack.com>"

ENV NGINX_VERSION   1.21.6
ENV NJS_VERSION     0.7.2
ENV PKG_RELEASE     1~bullseye

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup --system --gid 101 nginx \
    && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y gnupg1 ca-certificates nano curl wget htop nginx nginx-extras certbot gettext-base iputils-ping iftop \

# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
# create a docker-entrypoint.d directory
    && mkdir /docker-entrypoint.d

COPY entrypoint/docker-entrypoint.sh /
COPY entrypoint/10-listen-on-ipv6-by-default.sh /docker-entrypoint.d
COPY entrypoint/20-envsubst-on-templates.sh /docker-entrypoint.d
COPY entrypoint/30-tune-worker-processes.sh /docker-entrypoint.d
COPY entrypoint/80-letsencrypt.sh /docker-entrypoint.d
COPY snippets/* /etc/nginx/snippets/
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]