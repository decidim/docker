# Docker images for Decidim 

Images are mirrored on [Docker Hub](https://hub.docker.com/u/decidim) and [Github Container Registry](https://github.com/orgs/decidim/packages).

**Image naming has changed recently.**

We now use different names for images with different purposes, while previously we were using tagging to distinguish between them. CIs and scripts will need to be updated accordingly on updates after v0.23.1.

**Biggest naming change:** 

The app generator gem used to be called `decidim` and is now called `decidim-generator`. There's now a new `decidim` image for a fully functioning generated Decidim app.

Here's the complete list of images and their purposes:

## Images available

### decidim

Decidim app pre-generated with core modules.

Tagged as `decidim:latest` or `decidim:<version>` (eg: `decidim:0.23.1`). 

### decidim-generator

The [decidim gem](https://rubygems.org/gems/decidim) with all necessary environment for running it.

Tagged as `decidim-generator:latest` or `decidim-generator:<version>` (eg: `decidim-generator:0.23.1`).

### decidim-test

The above gem environment plus tooling for testing.

Tagged `decidim-test:latest` or `decidim-test:<version>` (eg: `decidim-test:0.23.1`).

### decidim-dev

The above plus more configuration for running local dev environment.

Tagged `decidim-dev:latest` or `decidim-dev:<version>` (eg: `decidim-dev:0.23.1`).

## Hello World with docker-compose

This repo includes a [docker-compose.yml](docker-compose.yml) file with:

- a Decidim service (using the `decidim:latest` image)
- a Postgres service
- a Redis service

By cloning the repo and then running `docker-compose up`, you'll get a fully functional Decidim app complete with seed data, accessible at http://localhost:3000.

```bash
git clone git@github.com:decidim/docker.git decidim-docker
cd decidim-docker
docker-compose up
```
It'll take a couple of minutes to run through all migrations and seeds. At the end you should see:

```
(...lots of migrating and seeding...)
decidim_1  | Puma starting in single mode...
decidim_1  | * Version 4.3.5 (ruby 2.6.6-p146), codename: Mysterious Traveller
decidim_1  | * Min threads: 5, max threads: 5
decidim_1  | * Environment: development
decidim_1  | * Listening on tcp://0.0.0.0:3000
decidim_1  | Use Ctrl-C to stop
```

Note: in case you run into SSL redirection errors, opening it on an incognito window usually solves the problem.

## Using the decidim app image individually

### Locally, with running local database

```bash
docker run -it --rm \
  -e DATABASE_USERNAME=postgres \
  -e DATABASE_PASSWORD=postgres \
  -e RAILS_ENV=development \
  -p 3000:3000 \
  ghcr.io/decidim/decidim:latest
```

### In production

```bash
docker run -it --rm \
  -e DATABASE_URL="postgres://user:pass@postgres-host/decidim-production-db" \
  -p 3000:3000 \
  ghcr.io/decidim/decidim:latest
```

## Using the decidim-generator image

With this image you can generate a new Decidim application:

```bash
APP_NAME=HelloWorld
IMAGE=ghcr.io/decidim/decidim-generator:latest
docker run -it -v "$(pwd):/code" ${IMAGE} decidim ${APP_NAME}
sudo chown -R $(whoami): ${APP_NAME}
```

From here on you can follow the steps on the [Getting Started](https://docs.decidim.org/en/install/) guide.

## Using a production deploy script

We've been working on a script that you can use to have a fully functional, production-ready decidim instance.

```bash
curl -fsSL https://decidim.org/install | bash
```

It will install the necessary tools to make decidim work on your server.

- Docker
- unzip
- UFW

The application will be hosted in the `/opt/decidim` directory by default, even though you can change it with `REPOSITORY_PATH` environment variable.

## App - Main Decidim Web Application
The app itself will be the container with the base image you decide (By default is the latest Decidim version: `decidim/decidim:latest`). You can change it with the `DECIDIM_IMAGE` environment variable.

This is the front-end web process users access in the browser.

## Worker
The worker will be the one responsible for all the background jobs that the application needs to run.

## Cache
The app needs a cache server. This will be a `redis:8-alpine` instance. This cache will be used both by the app and the worker.

## Database

The application needs a database to run. Through the installation process you will be asked if you have an already working database, if not, you will have a postgres container with all the schema and migrations run (It will be a `postgres:17-alpine`)

## Configuration

To configure the application you will have to answer some questions that will, at the end, generate a `.env` file. 

### Environment Variables Reference

To see the full list of Decidim Environment Variables, and that you can add to your generated `.env` file, you can take a look at the official [documentation](https://docs.decidim.org/en/develop/configure/environment_variables)

| Variable | Default | Used In | Description |
|----------|---------|---------|-------------|
| **BUNDLE_GEMFILE** | `Gemfile.wrapper` | app, worker | Selects which Gemfile the container should use. |
| **DECIDIM_IMAGE** | `decidim/decidim:latest` | app, worker | Overrides the Decidim Docker image version. |
| **DECIDIM_DOMAIN** | — | app, traefik | Domain for HTTPS routing and URL generation. |
| **SECRET_KEY_BASE** | — | app, worker | Rails secret key used for sessions and cookies. |
| **DATABASE_NAME** | `decidim` | db | PostgreSQL database name. |
| **DATABASE_USER** | `decidim` | db | PostgreSQL username. |
| **DATABASE_HOST** | `db` | app, worker | Hostname of your PostgreSQL instance. |
| **DATABASE_PASSWORD** | `decidim` | db | PostgreSQL user password. |
| **DATABASE_URL** | — | app, worker | Full PostgreSQL connection URL (overrides other DB vars). |
| **SMTP_USERNAME** | — | app, worker | Username for SMTP authentication. |
| **SMTP_PASSWORD** | — | app, worker | Password for SMTP authentication. |
| **SMTP_ADDRESS** | — | app, worker | SMTP server hostname. |
| **SMTP_DOMAIN** | — | app, worker | SMTP domain. |
| **SMTP_PORT** | — | app, worker | SMTP port. |
| **SMTP_STARTTLS_AUTO** | `true` | app | Enables STARTTLS automatically. |
| **REDIS_URL** | `redis://decidim_cache:6379/0` | app | Redis URL for cache + sessions. |
| **VAPID_PUBLIC_KEY** | — | app | Web Push public key for browser notifications. |
| **VAPID_PRIVATE_KEY** | — | app | Web Push private key (keep secret). |
| **CERTIFICATE_EMAIL** | — | traefik | Email used by Let's Encrypt for certificate issues/renewals. |
| **WEB_CONCURRENCY** | `2` | app | Puma concurrency setting. |
| **LOG_LEVEL** | `info` | app | Log level for Rails. |
| **DECIDIM_FORCE_SSL** | `false` | app | Enforce HTTPS-only traffic. |
| **MAPS_API_KEY** | — | app | API key for maps provider. |
| **MAPS_PROVIDER** | `here` | app | Selects map provider (here, mapbox, google, etc). |
