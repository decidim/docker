# Docker images for Decidim 

Images are mirrored on [Docker Hub](https://hub.docker.com/repository/docker/decidim/decidim) and [Github Container Registry](https://github.com/orgs/decidim/packages).

**Note that image naming has changed recently**. We now use different names for images with different purposes, while previously we were using tagging to distinguish between them. CIs and scripts will need to be updated accordingly on updates after v0.23.1.

Biggest naming change: the app generator gem used to be called `decidim` and is now called `decidim-generator`. 

Here's the complete list of images and their purposes:

## Images available

- `decidim-generator:latest` or `decidim-generator:<version>` (eg: `decidim-generator:0.23.1`): the [decidim gem](https://rubygems.org/gems/decidim) with all necessary environment for running it.
- `decidim-test:latest` or `decidim-test:<version>` (eg: `decidim-test:0.23.1`): the above gem environment plus tooling for testing.
- `decidim-dev:latest` or `decidim-dev:<version>` (eg: `decidim-dev:0.23.1`): the above plus more configuration for running local dev environment.
- `decidim:latest` or `decidim:<version>` (eg: `decidim:0.23.1`): actual generated Decidim app to be run locally.

## Using the decidim (app) image

With this image you can run a pre-generated Decidim app:


### Locally

```bash
docker run -it --rm \
  -e DATABASE_USERNAME=postgres \
  -e DATABASE_PASSWORD=postgres \
  -e DATABASE_HOST=host.docker.internal \
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
docker run -it -v "$(pwd):/code" ${IMAGE} ${APP_NAME}
sudo chown -R $(whoami): ${APP_NAME}
```

From here on you can follow the steps on the [Getting Started](https://github.com/decidim/decidim/blob/master/docs/getting_started.md) guide.

### Using decidim-generator with docker-compose

The generator image can be used in conjunction with docker-compose, and the core [decidim/decidim](https://github.com/decidim/decidim) repo already offers a [docker-compose.yml](https://github.com/decidim/decidim/blob/develop/docker-compose.yml) file.

The flow is to checkout the [decidim/decidim](https://github.com/decidim/decidim) repo and then `docker-compose up`:

```bash
git clone git@github.com:decidim/decidim.git
cd decidim
docker-compose up
```
