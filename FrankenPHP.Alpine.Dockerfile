ARG PHP_VERSION=8.4
ARG FRANKENPHP_VERSION=1.9
ARG COMPOSER_VERSION=2.8

FROM composer:${COMPOSER_VERSION} AS vendor

FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-builder-php${PHP_VERSION}-alpine AS upstream

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

FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}-alpine

COPY --from=upstream /usr/local/bin/frankenphp /usr/local/bin/frankenphp

LABEL maintainer="Mortexa <seyed.me720@gmail.com>"
LABEL org.opencontainers.image.title="Laravel Docker Setup"
LABEL org.opencontainers.image.description="Production-ready Docker Setup for Laravel"
LABEL org.opencontainers.image.source=https://github.com/exaco/laravel-docktane
LABEL org.opencontainers.image.licenses=MIT

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG TZ=UTC

ENV TERM=xterm-color \
    OCTANE_SERVER=frankenphp \
    TZ=${TZ} \
    USER=laravel \
    ROOT=/var/www/html \
    APP_ENV=production \
    COMPOSER_FUND=0 \
    COMPOSER_MAX_PARALLEL_HTTP=48 \
    WITH_HORIZON=false \
    WITH_SCHEDULER=false \
    WITH_REVERB=false

ENV XDG_CONFIG_HOME=${ROOT}/.config XDG_DATA_HOME=${ROOT}/.data

WORKDIR ${ROOT}

SHELL ["/bin/sh", "-eou", "pipefail", "-c"]

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone

RUN apk update; \
    apk upgrade; \
    apk add --no-cache \
    curl \
    wget \
    vim \
    tzdata \
    ncdu \
    procps \
    unzip \
    ca-certificates \
    bash \
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
    && docker-php-source delete \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

RUN arch="$(apk --print-arch)" \
    && case "$arch" in \
    armhf) _cronic_fname='supercronic-linux-arm' ;; \
    aarch64) _cronic_fname='supercronic-linux-arm64' ;; \
    x86_64) _cronic_fname='supercronic-linux-amd64' ;; \
    x86) _cronic_fname='supercronic-linux-386' ;; \
    *) echo >&2 "error: unsupported architecture: $arch"; exit 1 ;; \
    esac \
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.38/${_cronic_fname}" \
    -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir -p /etc/supercronic \
    && echo "*/1 * * * * php ${ROOT}/artisan schedule:run --no-interaction" > /etc/supercronic/laravel

RUN addgroup -g ${GROUP_ID} ${USER} \
    && adduser -D -G ${USER} -u ${USER_ID} -s /bin/sh ${USER}

RUN cp ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

COPY --link --from=vendor /usr/bin/composer /usr/bin/composer
COPY --link deployment/supervisord.conf /etc/
COPY --link deployment/octane/FrankenPHP/supervisord.frankenphp.conf /etc/supervisor/conf.d/
COPY --link deployment/supervisord.*.conf /etc/supervisor/conf.d/
COPY --link deployment/start-container /usr/local/bin/start-container
COPY --link deployment/healthcheck /usr/local/bin/healthcheck
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
    storage/framework/sessions \
    storage/framework/views \
    storage/framework/cache \
    storage/framework/testing \
    storage/logs \
    bootstrap/cache \
    && chown -R ${USER_ID}:${GROUP_ID} ${ROOT} \
    && chmod +x /usr/local/bin/start-container /usr/local/bin/healthcheck

RUN composer dump-autoload \
    --optimize \
    --apcu \
    --no-dev

RUN bun run build

USER ${USER}

EXPOSE 8000
EXPOSE 2019
EXPOSE 8080

ENTRYPOINT ["start-container"]

HEALTHCHECK --start-period=5s --interval=1s --timeout=3s --retries=10 CMD healthcheck || exit 1