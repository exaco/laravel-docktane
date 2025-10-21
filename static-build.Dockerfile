ARG PHP_VERSION=8.4
ARG FRANKENPHP_VERSION=1.8
ARG COMPOSER_VERSION=2.8

FROM composer:${COMPOSER_VERSION} AS vendor

FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-builder-php${PHP_VERSION} AS upstream

COPY --from=caddy:builder /usr/bin/xcaddy /usr/bin/xcaddy

RUN CGO_ENABLED=1 \
    XCADDY_SETCAP=1 \
    XCADDY_GO_BUILD_FLAGS="-ldflags='-w -s' -tags=nobadger,nomysql,nopgx" \
    CGO_CFLAGS=$(php-config --includes) \
    CGO_LDFLAGS="$(php-config --ldflags) $(php-config --libs)" \
    xcaddy build \
        --output /usr/local/bin/frankenphp \
        --with github.com/dunglas/frankenphp=./ \
        --with github.com/dunglas/frankenphp/caddy=./caddy/ \
        --with github.com/dunglas/caddy-cbrotli

FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}

COPY --from=upstream /usr/local/bin/frankenphp /usr/local/bin/frankenphp

LABEL maintainer="Mortexa <seyed.me720@gmail.com>"
LABEL org.opencontainers.image.title="Laravel Docker Setup"
LABEL org.opencontainers.image.description="Production-ready Docker Setup for Laravel"
LABEL org.opencontainers.image.source=https://github.com/exaco/laravel-docktane
LABEL org.opencontainers.image.licenses=MIT

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG TZ=UTC

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-color \
    OCTANE_SERVER=frankenphp \
    TZ=${TZ} \
    USER=laravel \
    ROOT=/var/www/html \
    APP_ENV=production \
    COMPOSER_FUND=0 \
    COMPOSER_MAX_PARALLEL_HTTP=48

ENV XDG_CONFIG_HOME=${ROOT}/.config XDG_DATA_HOME=${ROOT}/.data

WORKDIR ${ROOT}

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone

RUN echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom && \
    echo "Acquire::BrokenProxy    true;" >> /etc/apt/apt.conf.d/99custom

RUN apt-get update; \
    apt-get upgrade -yqq; \
    apt-get install -yqq --no-install-recommends --show-progress \
    apt-utils \
    curl \
    wget \
    vim \
    unzip \
    ncdu \
    procps \
    ca-certificates \
    supervisor \
    libsodium-dev \
    && curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr bash \
    && install-php-extensions \
    apcu \
    bz2 \
    pcntl \
    mbstring \
    bcmath \
    sockets \
    pdo_pgsql \
    opcache \
    exif \
    pdo_mysql \
    zip \
    uv \
    intl \
    gd \
    redis \
    rdkafka \
    ffi \
    ldap \
    && apt-get -y autoremove \
    && apt-get clean \
    && docker-php-source delete \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/lastlog /var/log/faillog

RUN userdel --remove --force www-data \
    && groupadd --force -g ${GROUP_ID} ${USER} \
    && useradd -ms /bin/bash --no-log-init --no-user-group -g ${GROUP_ID} -u ${USER_ID} ${USER} \
    && setcap -r /usr/local/bin/frankenphp

RUN cp ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

USER ${USER}

COPY --link --from=vendor /usr/bin/composer /usr/bin/composer
COPY --link deployment/php.ini ${PHP_INI_DIR}/conf.d/99-php.ini
COPY --link composer.* ./

RUN composer install \
    --no-dev \
    --no-interaction \
    --no-autoloader \
    --no-ansi \
    --no-scripts \
    --no-progress \
    --audit

COPY --link package.json bun.lock* ./

RUN bun install --frozen-lockfile

COPY --link . .

RUN mkdir -p \
    storage/framework/{sessions,views,cache,testing} \
    storage/logs \
    bootstrap/cache \
    && chown -R ${USER_ID}:${GROUP_ID} ${ROOT}

RUN composer dump-autoload \
    --optimize \
    --apcu \
    --no-dev

RUN bun run build

###########################################

FROM --platform=linux/amd64 dunglas/frankenphp:static-builder-${FRANKENPHP_VERSION} AS static

WORKDIR /go/src/app/dist/app

COPY --link --from=runner . .

RUN rm -Rf tests/

ENV NO_COMPRESS=true

WORKDIR /go/src/app/

RUN EMBED=dist/app/ ./build-static.sh
