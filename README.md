<div align="center">
 <h1>Laravel Docker Setup</h1>
</div>
<div align="center">
 <a href="/LICENSE"><img alt="License" src="https://img.shields.io/github/license/exaco/laravel-docktane"></a>
 <a href="https://github.com/exaco/laravel-docktane/releases"><img alt="GitHub release (latest by date)" src="https://img.shields.io/github/v/release/exaco/laravel-docktane"></a>
 <a href="https://github.com/exaco/laravel-docktane/pulls"><img alt="GitHub closed pull requests" src="https://img.shields.io/github/issues-pr-closed/exaco/laravel-docktane"></a>
 <br>
 <a href="https://github.com/exaco/laravel-docktane/actions/workflows/tests.yml"><img alt="GitHub Workflow Status" src="https://github.com/exaco/laravel-docktane/actions/workflows/roadrunner-test.yml/badge.svg"></a>
 <a href="https://github.com/exaco/laravel-docktane/actions/workflows/tests.yml"><img alt="GitHub Workflow Status" src="https://github.com/exaco/laravel-docktane/actions/workflows/swoole-test.yml/badge.svg"></a>
 <a href="https://github.com/exaco/laravel-docktane/actions/workflows/tests.yml"><img alt="GitHub Workflow Status" src="https://github.com/exaco/laravel-docktane/actions/workflows/frankenphp-test.yml/badge.svg"></a>
 <a href="https://github.com/exaco/laravel-docktane/actions/workflows/tests.yml"><img alt="GitHub Workflow Status" src="https://github.com/exaco/laravel-docktane/actions/workflows/compose-test.yaml/badge.svg"></a>
</div>
<br>

A production-ready Docker setup for running high-performance Laravel applications with Laravel Octane. This repository provides Dockerfiles and a comprehensive Docker Compose configuration for various Octane drivers, including Swoole, RoadRunner, and FrankenPHP.

The setup is optimized for performance and includes multi-stage builds to create lean final images.

## Key Features

- **Multiple Drivers:** Dockerfiles available for Swoole, RoadRunner, and FrankenPHP.
- **Production-Ready:** Optimized for a production environment with best practices.
- **Multi-Stage Builds:** Creates smaller, more secure Docker images by separating build dependencies from the final runtime image.
- **Container Modes:** Easily run your container in different modes for handling web requests (`http`), queues (`horizon`), scheduled tasks (`scheduler`), custom worker (`worker`), or WebSocket server (`reverb`).
- **Extensible:** Simple to customize for your specific application needs.
- **Comprehensive Docker Compose:** Includes a production-ready `compose.production.yaml` to orchestrate the full application stack.


## Laravel Container modes

Easily launch your container in different modes to handle specific tasks:


| Mode                  | `CONTAINER_MODE` value | Description
| --------------------- | ---------------- | ---------------- |
| HTTP Server (default) | `http` | Runs your Laravel Octane application.        |
| Horizon               | `horizon`        | Manages your queued jobs efficiently.        |
| Scheduler             | `scheduler`      | Executes scheduled tasks at defined intervals.        |
| Worker                | `worker`         | A dedicated worker for background processing.        |
| Reverb                | `reverb`         | Facilitates real-time communication with Laravel Echo.        |

## Production-Ready Docker Compose

For a complete production environment, this repository includes a `compose.production.yaml` file to orchestrate a full stack of services. This setup is security-hardened and provides a comprehensive solution for deploying and managing your application.

The orchestrated containers include:

- **Application:** Your Laravel Octane application running in http mode to serve web requests.
- **Horizon:** A dedicated container for running Laravel Horizon to manage your Redis queues.
- **Scheduler:** A container responsible for executing Laravel's scheduled tasks. 
- **Database:** A PostgreSQL container for your application's database.
- **PgBouncer:** Lightweight connection pooler for PostgreSQL.
- **Redis:** An in-memory data store used for caching and as a message broker for Laravel Horizon.
- **Minio:** An S3-compatible object storage service, perfect for handling file uploads and storage.
- **Typesense:** A fast, typo-tolerant, and open-source search engine for building powerful search functionality into your application.
- **pgAdmin & pghero:** Web-based tools for managing your PostgreSQL database and monitoring its performance.
- **Backup Service:** A container that performs automated backups of your database to ensure data safety.
- **System Monitoring:** Includes Netdata containers to provide real-time insights and monitoring for your entire infrastructure.
- **Prometheus:** A powerful time-series database used for collecting metrics from your application and the host system.
- **Grafana:** A leading open-source platform for monitoring and observability, used to visualize the metrics collected by Prometheus in beautiful dashboards.

This comprehensive stack provides a robust and observable environment for your production application.

## Prerequisites

- Docker installed on your system
- Docker Compose installed on your system
- Setup Laravel Octane, Laravel Horizon and Laravel Reverb

## Usage

### Building Docker image

1. Clone the repository:
```
git clone --depth 1 git@github.com:exaco/laravel-docktane.git
```
2. Copy the contents of the cloned directory, including the following items, into your Laravel project powered by Octane:
   - `deployment` directory
   - `<your-octane-driver>.Dockerfile`
   - `.dockerignore` 
    
1. Change the directory to your Laravel project
2. Build your image:
```
docker build -t <image-name>:<tag> -f <your-octane-driver>.Dockerfile .
```

### Running Docker container

```bash
# HTTP mode
docker run -p <port>:8000 --rm <image-name>:<tag>

# Horizon mode
docker run -e CONTAINER_MODE=horizon --rm <image-name>:<tag>

# Scheduler mode
docker run -e CONTAINER_MODE=scheduler --rm <image-name>:<tag>

# Reverb mode
docker run -e CONTAINER_MODE=reverb --rm <image-name>:<tag>

# HTTP mode with Horizon
docker run -e WITH_HORIZON=true -p <port>:8000 --rm <image-name>:<tag>

# HTTP mode with Scheduler
docker run -e WITH_SCHEDULER=true -p <port>:8000 --rm <image-name>:<tag>

# HTTP mode with Scheduler and Horizon
docker run \
    -e WITH_SCHEDULER=true \
    -e WITH_HORIZON=true \
    -p <port>:8000 \
    --rm <image-name>:<tag>

# HTTP mode with Scheduler, Horizon and Reverb
docker run \
    -e WITH_SCHEDULER=true \
    -e WITH_HORIZON=true \
    -e WITH_REVERB=true \
    -p <port>:8000 \
    --rm <image-name>:<tag>

# Worker mode
docker run \
    -e CONTAINER_MODE=worker \
    -e WORKER_COMMAND="php /var/www/html/artisan foo:bar" \
    --rm <image-name>:<tag>

# Running a single command
docker run --rm <image-name>:<tag> php artisan about
```

### Docker Compose

To deploy your application stack with Docker Compose:
1. Copy the following items to your code base:
    - `compose.production.yaml`
    - `.env.production`
    - `Makefile`
2. Edit `.env.production` and populate it with the appropriate values for your production environment variables (e.g., database credentials, API keys).
3. Run the command `make up` to start the containers.

> [!NOTE]  
> The included `Makefile` offers a range of additional commands for managing your deployment, including options for rebuilding, stopping, and restarting services.

> [!CAUTION]
> Do not forget to edit `.env.production`!

## Configuration and Customization

* You can use the `APP_ENV` build argument to specify a different environment file.

### Recommended options in `octane.php`

```php
// config/octane.php

return [
    'swoole' => [
        'options' => [
            'http_compression' => true,
            'http_compression_level' => 6, // 1 - 9
            'compression_min_length' => 20,
            'package_max_length' => 2 * 1024 * 1024, // 2MB
            'upload_max_filesize' => 20 * 1024 * 1024, // 20MB
            'open_http2_protocol' => true,
            'document_root' => public_path(),
            'enable_static_handler' => true,
        ]
    ],

    // https://github.com/laravel/octane/pull/853#issuecomment-1999530137
    'state_file' => base_path('bootstrap/octane-server-state.json'),

    // https://github.com/laravel/octane/pull/902/files
    'usleep_between_writing_server_output' => 1,
];
```

## Essential Notes

* Some configurations are highly opinionated, so please make sure they align with your needs.
* Laravel Octane logs request information only in the `local` environment.
* Be mindful of the contents of the `.dockerignore` file.

## ToDo
- [x] Add Docker Compose
- [x] Add support for PHP 8.4
- [x] Add support for worker mode
- [x] Build assets with Bun
- [x] Install more Caddy modules
- [x] Create standalone and self-executable app
- [x] Add support for Horizon
- [x] Add support for RoadRunner
- [x] Add support for FrankenPHP
- [x] Add support for Laravel Reverb
- [x] Add support for the full-stack apps (Front-end assets)
- [ ] Add support `testing` environment and CI
- [x] Add support for the Laravel scheduler
- [ ] Add support for Laravel Dusk
- [x] Support more PHP extensions
- [x] Add tests
- [x] Add Alpine-based images

## Contributing

Thank you for considering contributing! If you find an issue, or have a better way to do something, feel free to open an
issue, or a PR.

## Credits

- [Mortexa](https://github.com/smortexa)
- [All contributors](https://github.com/exaco/laravel-docktane/graphs/contributors)

## License

This repository is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
