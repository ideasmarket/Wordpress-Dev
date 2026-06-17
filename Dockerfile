# ── Stage 1: Composer dependencies ────────────────────────────────────────────
FROM composer:2 AS composer

WORKDIR /app

# Copy only manifest files first so this layer is cached unless deps change
COPY composer.json composer.lock ./

RUN composer install \
      --no-dev \
      --no-interaction \
      --no-progress \
      --prefer-dist \
      --optimize-autoloader

# ── Stage 2: Runtime image ────────────────────────────────────────────────────
FROM php:8.3-fpm-alpine AS runtime

# Install runtime extensions required by WordPress + Bedrock
RUN apk add --no-cache \
      nginx \
      bash \
      less \
      mariadb-client \
      imagemagick \
      libpng libpng-dev libjpeg-turbo libjpeg-turbo-dev \
      libzip-dev \
    && docker-php-ext-install \
      pdo_mysql \
      mysqli \
      exif \
      zip \
      gd \
    && apk del libpng-dev libjpeg-turbo-dev \
    && rm -rf /var/cache/apk/*

# Install WP-CLI — useful for kamal app exec one-liners (db import, cache flush, etc.)
RUN curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

WORKDIR /var/www/html

# Pull in Composer-managed vendor + WordPress core from stage 1
COPY --from=composer /app/vendor ./vendor
COPY --from=composer /app/web/wp ./web/wp

# Copy the rest of the Bedrock project (config/, web/app/, .env is NOT copied — injected at runtime)
COPY . .

# wp-content/uploads is a persistent volume; ensure the path exists
RUN mkdir -p web/app/uploads \
    && chown -R www-data:www-data /var/www/html

# Nginx config — Bedrock rewrites root to /web
COPY docker/nginx.conf /etc/nginx/nginx.conf

# PHP-FPM tuning (optional, mount your own for per-client overrides)
COPY docker/php-fpm.conf /usr/local/etc/php-fpm.d/zz-custom.conf

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

# Kamal expects a single long-running process; entrypoint starts php-fpm + nginx
ENTRYPOINT ["/entrypoint.sh"]