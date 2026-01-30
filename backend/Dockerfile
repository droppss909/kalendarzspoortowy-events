FROM serversideup/php:8.4-fpm-nginx-alpine

ENV PHP_OPCACHE_ENABLE=1

# NIE wymuszaj user/group w FPM (na OpenShift to często psuje start)
# Usuń ten blok jeśli masz:
# RUN echo "user = www-data" ... itd.

USER root

RUN install-php-extensions intl

COPY . .

# OpenShift: allow random UID (group 0) to write where entrypoint needs it
RUN set -eux; \
  mkdir -p /var/cache/nginx /var/run /var/log/nginx /etc/nginx/site-opts.d; \
  chgrp -R 0 /etc/nginx /var/cache/nginx /var/run /var/log/nginx /var/www/html; \
  chmod -R g=u /etc/nginx /var/cache/nginx /var/run /var/log/nginx /var/www/html

RUN mkdir -p /etc/nginx/site-opts.d \
 && chgrp -R 0 /etc/nginx/site-opts.d \
 && chmod -R g=u /etc/nginx/site-opts.d \
 && chmod g+s /etc/nginx/site-opts.d

# Laravel writable dirs
RUN mkdir -p storage bootstrap/cache \
 && chmod -R g=u storage bootstrap/cache

RUN mkdir -p /run/nginx \
 && chgrp -R 0 /run/nginx \
 && chmod -R g=u /run/nginx

RUN composer install \
  --ignore-platform-reqs \
  --no-interaction \
  --no-dev \
  --optimize-autoloader \
  --prefer-dist

EXPOSE 8080

