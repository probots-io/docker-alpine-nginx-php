FROM php:7.1.0-fpm-alpine

# https://github.com/smebberson/docker-alpine/tree/master/alpine-base
# https://github.com/prooph/docker-files/blob/master/php/7.1-fpm

ENV S6_OVERLAY_VERSION=v1.18.1.5 \
    GODNSMASQ_VERSION=1.0.7 \
    NGINX_VERSION=1.10.1-r1 \
    XDEBUG_VERSION=2.5.0

ENV PHPIZE_DEPS \
    autoconf \
    cmake \
    file \
    g++ \
    gcc \
    libc-dev \
    make \
    pkgconf \
    re2c

WORKDIR /


RUN apk add --no-cache --virtual .persistent-deps bind-tools git bash nginx=${NGINX_VERSION} mysql-client
RUN apk add --no-cache --virtual .build-deps curl $PHPIZE_DEPS

# Install Whatever is needed
RUN set -xe \
    # S6
    && curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz | tar xfz - -C / \
    # Go DNS MASQ
    && curl -sSL https://github.com/janeczku/go-dnsmasq/releases/download/${GODNSMASQ_VERSION}/go-dnsmasq-min_linux-amd64 -o /bin/go-dnsmasq \
    # Composer
    && curl -sS https://getcomposer.org/installer | php -- --filename=/usr/local/bin/composer \
    # XDebug
    # && pecl install xdebug-${XDEBUG_VERSION} \

    # create user and give binary permissions to bind to lower port
    && chmod +x /bin/go-dnsmasq \
    && addgroup go-dnsmasq \
    && adduser -D -g "" -s /bin/sh -G go-dnsmasq go-dnsmasq \
    && setcap CAP_NET_BIND_SERVICE=+eip /bin/go-dnsmasq \

    # Install nginx
    && chown -R nginx:www-data /var/lib/nginx \

    # Remove basic config
    && rm -r /usr/local/etc/* \
    && rm -rf /var/cache/apk/* \
    && apk del .build-deps \

    # Create App Dir
    && rm -rf /var/www/* \
    && mkdir /var/www/app

# Add docker files
ADD docker /

# Install/Enable PHP Extensions: TODO: MISSING!!!!!!!!
RUN docker-php-ext-install pdo pdo_mysql bcmath
    # && docker-php-ext-enable xdebug

# Expose the ports for nginx
EXPOSE 80

WORKDIR /var/www/app

ENTRYPOINT ["/init"]
