ARG PHP_VERSION=8.4.12
ARG COMPOSER_VERSION=2.8
ARG BUN_VERSION="latest"
ARG ROOT="/var/www/html"

FROM composer:${COMPOSER_VERSION} AS vendor

FROM php:${PHP_VERSION}-cli-bookworm AS base

LABEL maintainer="SMortexa <seyed.me720@gmail.com>"
LABEL org.opencontainers.image.title="Laravel Octane Dockerfile"
LABEL org.opencontainers.image.description="Production-ready Dockerfile for Laravel Octane"
LABEL org.opencontainers.image.source=https://github.com/exaco/laravel-octane-dockerfile
LABEL org.opencontainers.image.licenses=MIT

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG TZ=UTC
ARG APP_ENV
ARG ROOT

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-color \
    OCTANE_SERVER=roadrunner \
    TZ=${TZ} \
    USER=octane \
    APP_ENV=${APP_ENV} \
    ROOT=${ROOT} \
    COMPOSER_FUND=0 \
    COMPOSER_MAX_PARALLEL_HTTP=48

WORKDIR ${ROOT}

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo ${TZ} > /etc/timezone

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN apt-get update; \
    apt-get upgrade -yqq; \
    apt-get install -yqq --no-install-recommends --show-progress \
    apt-utils \
    curl \
    wget \
    vim \
    ncdu \
    procps \
    unzip \
    ca-certificates \
    supervisor \
    libsodium-dev \
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
    memcached \
    ldap \
    && apt-get -y autoremove \
    && apt-get clean \
    && docker-php-source delete \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/lastlog /var/log/faillog

RUN arch="$(uname -m)" \
    && case "$arch" in \
    armhf) _cronic_fname='supercronic-linux-arm' ;; \
    aarch64) _cronic_fname='supercronic-linux-arm64' ;; \
    x86_64) _cronic_fname='supercronic-linux-amd64' ;; \
    x86) _cronic_fname='supercronic-linux-386' ;; \
    *) echo >&2 "error: unsupported architecture: $arch"; exit 1 ;; \
    esac \
    && wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.29/${_cronic_fname}" \
    -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir -p /etc/supercronic \
    && echo "*/1 * * * * php ${ROOT}/artisan schedule:run --no-interaction" > /etc/supercronic/laravel

RUN userdel --remove --force www-data \
    && groupadd --force -g ${GROUP_ID} ${USER} \
    && useradd -ms /bin/bash --no-log-init --no-user-group -g ${GROUP_ID} -u ${USER_ID} ${USER}

RUN chown -R ${USER_ID}:${GROUP_ID} ${ROOT} /var/{log,run} \
    && chmod -R a+rw ${ROOT} /var/{log,run}

RUN cp ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

USER ${USER}

COPY --link --chown=${USER_ID}:${GROUP_ID} --from=vendor /usr/bin/composer /usr/bin/composer

COPY --link --chown=${USER_ID}:${GROUP_ID} deployment/supervisord.conf /etc/
COPY --link --chown=${USER_ID}:${GROUP_ID} deployment/octane/RoadRunner/supervisord.roadrunner.conf /etc/supervisor/conf.d/
COPY --link --chown=${USER_ID}:${GROUP_ID} deployment/supervisord.*.conf /etc/supervisor/conf.d/
COPY --link --chown=${USER_ID}:${GROUP_ID} deployment/php.ini ${PHP_INI_DIR}/conf.d/99-octane.ini
COPY --link --chown=${USER_ID}:${GROUP_ID} deployment/octane/RoadRunner/.rr.prod.yaml ./.rr.yaml
COPY --link --chown=${USER_ID}:${GROUP_ID} deployment/start-container /usr/local/bin/start-container
COPY --link --chown=${USER_ID}:${GROUP_ID} deployment/healthcheck /usr/local/bin/healthcheck

RUN chmod +x /usr/local/bin/start-container /usr/local/bin/healthcheck

###########################################

FROM base AS common

USER ${USER}

COPY --link --chown=${USER_ID}:${GROUP_ID} . .

RUN composer install \
    --no-dev \
    --no-interaction \
    --no-autoloader \
    --no-ansi \
    --no-scripts \
    --audit

###########################################
# Build frontend assets with Bun
###########################################

FROM oven/bun:${BUN_VERSION} AS build

ARG ROOT

WORKDIR ${ROOT}

COPY --link package.json bun.lock* ./

RUN bun install --frozen-lockfile

COPY --link --from=common ${ROOT} .

RUN bun run build

###########################################

FROM common AS runner

USER ${USER}

ENV WITH_HORIZON=false \
    WITH_SCHEDULER=false \
    WITH_REVERB=false

COPY --link --chown=${USER_ID}:${GROUP_ID} --from=build ${ROOT}/public public

RUN mkdir -p \
    storage/framework/{sessions,views,cache,testing} \
    storage/logs \
    bootstrap/cache && chmod -R a+rw storage

RUN composer dump-autoload \
    --optimize \
    --apcu \
    --no-dev

RUN if composer show | grep spiral/roadrunner-cli >/dev/null; then \
    ./vendor/bin/rr get-binary --quiet; else \
    echo "`spiral/roadrunner-cli` package is not installed. Exiting..."; exit 1; \
    fi

RUN chmod +x rr

EXPOSE 8000
EXPOSE 6001
EXPOSE 8080

ENTRYPOINT ["start-container"]

HEALTHCHECK --start-period=5s --interval=2s --timeout=5s --retries=8 CMD healthcheck || exit 1
