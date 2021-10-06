#!/bin/sh
# vim:sw=4:ts=4:et

set -e

if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
    exec 3>&1
else
    exec 3>/dev/null
fi

# run -----------------------------------------------------------
# set default conf

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
# TODO: fix to auto discover
echo "resolver  127.0.0.11 valid=30s;" > /etc/nginx/conf.d/10-resolver.conf
# if ! grep -q 'resolver' /etc/nginx/conf.d/10-resolver.conf; then
#     RESOLVERRAW=$(awk 'BEGIN{ORS=" "} $1=="nameserver" {print $2}' /etc/resolv.conf)
#     for i in ${RESOLVERRAW}; do
#         if [ $(awk -F ':' '{print NF-1}' <<< ${i}) -le 2 ]; then
#             RESOLVER="${RESOLVER} ${i}"
#         fi
#     done
#     if [ -z "${RESOLVER}" ]; then
#         RESOLVER="127.0.0.11"
#     fi
#     echo "Setting resolver to ${RESOLVER}"
#     echo -e "# This file is auto-generated on start, based on the container's /etc/resolv.conf file. Feel free to modify it as you wish.\n\nresolver ${RESOLVER} valid=30s;" > /etc/nginx/conf.d/10-resolver.conf
# fi

# service nginx restart

# default continued ---------------------------------------------
if [ "$1" = "nginx" -o "$1" = "nginx-debug" ]; then
    if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
        echo >&3 "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

        echo >&3 "$0: Looking for shell scripts in /docker-entrypoint.d/"
        find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
            case "$f" in
                *.sh)
                    if [ -x "$f" ]; then
                        echo >&3 "$0: Launching $f";
                        "$f"
                    else
                        # warn on shell scripts without exec bit
                        echo >&3 "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *) echo >&3 "$0: Ignoring $f";;
            esac
        done

        echo >&3 "$0: Configuration complete; ready for start up"
    else
        echo >&3 "$0: No files found in /docker-entrypoint.d/, skipping configuration"
    fi
fi

exec "$@"