# Laravel Octane Dockerfile
<a href="/LICENSE"><img alt="License" src="https://img.shields.io/github/license/exaco/laravel-octane-dockerfile"></a>
<a href="https://github.com/exaco/laravel-octane-dockerfile/releases"><img alt="GitHub release (latest by date)" src="https://img.shields.io/github/v/release/exaco/laravel-octane-dockerfile"></a>
<a href="https://github.com/exaco/laravel-octane-dockerfile/pulls"><img alt="GitHub closed pull requests" src="https://img.shields.io/github/issues-pr-closed/exaco/laravel-octane-dockerfile"></a>
<a href="https://github.com/exaco/laravel-octane-dockerfile/actions/workflows/tests.yml"><img alt="GitHub Workflow Status" src="https://github.com/exaco/laravel-octane-dockerfile/actions/workflows/roadrunner-test.yml/badge.svg"></a>
<a href="https://github.com/exaco/laravel-octane-dockerfile/actions/workflows/tests.yml"><img alt="GitHub Workflow Status" src="https://github.com/exaco/laravel-octane-dockerfile/actions/workflows/swoole-test.yml/badge.svg"></a>


A pretty configurable, production-ready, and multi-stage Dockerfile for [Laravel Octane](https://github.com/laravel/octane)
powered web services and microservices.

The Docker configuration provides the following setup:

- PHP 8.1, 8.2 and 8.3 official DebianBookworm-based images
- Preconfigured JIT compiler and OPcache

## Container modes

You can run the Docker container in different modes:

| Mode             | `CONTAINER_MODE` | HTTP server |
|------------------|----------------------|------------|
| HTTP Server (default) | `http`                | Swoole / RoadRunner |
| Horizon          | `horizon`            | - |
| Scheduler        | `scheduler`          | - |

## Usage

### Building Docker image
1. Clone this repository:
```
git clone --depth 1 git@github.com:exaco/laravel-octane-dockerfile.git
```
2. Copy cloned directory content including `deployment` directory, `Dockerfile`, and `.dockerignore` into your Octane powered Laravel project
3. Change the directory to your Laravel project
4. Build your image:
```
docker build -t <image-name>:<tag> -f Dockerfile.<your-octane-driver> .
```
### Running the Docker container

```bash
# http mode
docker run -p <port>:9000 --rm <image-name>:<tag>

# horizon mode
docker run -e CONTAINER_MODE=horizon -p <port>:9000 --rm <image-name>:<tag>

# scheduler mode
docker run -e CONTAINER_MODE=scheduler -p <port>:9000 --rm <image-name>:<tag>

# http mode with horizon
docker run -e WITH_HORIZON=true -p <port>:9000 --rm <image-name>:<tag>

# http mode with scheduler
docker run -e WITH_SCHEDULER=true -p <port>:9000 --rm <image-name>:<tag>
```

## Configuration

### Recommended `Swoole` options in `octane.php`

```php
// config/octane.php

return [
    'swoole' => [
        'options' => [
            'http_compression' => true,
            'http_compression_level' => 6, // 1 - 9
            'compression_min_length' => 20,
            'package_max_length' => 20 * 1024 * 1024, // 20MB
            'open_http2_protocol' => true,
            'document_root' => public_path(),
            'enable_static_handler' => true,
        ]
    ]
];
```

## Utilities

Also, some useful Bash functions and aliases are added in `utilities.sh` that maybe help.

## Notes

- Laravel Octane logs request information only in the `local` environment.
- Please be aware of `.dockerignore` content

## ToDo
- [x] Add support for PHP 8.3
- [ ] Create standalone and self-executable app
- [x] Add support for Horizon
- [x] Add support for RoadRunner
- [ ] Add support for FrankenPHP
- [x] Add support for the full-stack apps (Front-end assets)
- [ ] Add support `testing` environment and CI
- [x] Add support for the Laravel scheduler
- [ ] Add support for Laravel Dusk
- [ ] Support more PHP extensions
- [x] Add tests
- [ ] Add Alpine-based images

## Contributing

Thank you for considering contributing! If you find an issue, or have a better way to do something, feel free to open an
issue, or a PR.

## Credits
- [SMortexa](https://github.com/smortexa)
- [All contributors](https://github.com/exaco/laravel-octane-dockerfile/graphs/contributors)

## License

This repository is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
