#!/bin/sh
# docker/entrypoint.sh
# PID 1 is nginx; php-fpm runs as a background daemon
# sh instead of bash — alpine doesn't guarantee bash

set -e

# Run composer install in case vendor is missing (e.g. first bind-mount in dev)
if [ ! -f /var/www/html/vendor/autoload.php ]; then
    composer install \
        --no-interaction \
        --no-progress \
        --optimize-autoloader \
        --working-dir=/var/www/html
fi

# Fix permissions on uploads dir — relevant when bind-mounting in dev
chown -R www-data:www-data /var/www/html/web/app/uploads 2>/dev/null || true

# Start php-fpm as daemon
php-fpm -D

# Verify php-fpm actually started before handing off to nginx
timeout 5 sh -c 'until nc -z 127.0.0.1 9000; do sleep 0.2; done' || {
    echo "php-fpm failed to start" >&2
    exit 1
}

# nginx takes PID 1 — receives SIGTERM from Docker/Kamal on container stop
exec nginx -g 'daemon off;'
