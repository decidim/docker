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
