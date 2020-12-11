# Docker images for Decidim 

We're in the process of adopting Github Actions for our automated image build and publishing, and while that flow currently only publishes to Github Container Registry, there's another earlier flow on circleci publishing images to Docker Hub.

Instructions for using the generator and app images can be found below the information on each registry.

## Docker Hub images


We plan to phase out the circleci flow soon, and publish to Docker Hub with Github Actions as well.

You'll find the images here: https://hub.docker.com/r/decidim/decidim/tags

There's different tags for different usage scenarios:

- `decidim:latest` or `decidim:<version>` (eg: `decidim:0.23.1`): the [decidim gem](https://rubygems.org/gems/decidim) with all necessary environment for running it.
- `decidim:latest-test` or `decidim:<version>-test` (eg: `decidim:0.23.1-test`): the above gem environment plus tooling for testing.
- `decidim:latest-dev` or `decidim:<version>-dev` (eg: `decidim:0.23.1-dev`): the above plus more configuration for running local dev environment.
- `decidim:latest-deploy` or `decidim:<version>-deploy` (eg: `decidim:0.23.1-deploy`): actual generated Decidim app to be run locally.

## Github Registry Images

Naming has changed for images published on the new Github flow. We now use different names for images with different purposes, as opposed to using tagging to distinguish between them. Also, the app generator gem is now called `decidim-generator`.

- `decidim-generator:latest` or `decidim-generator:<version>` (eg: `decidim-generator:0.23.1`): the [decidim gem](https://rubygems.org/gems/decidim) with all necessary environment for running it.
- `decidim-test:latest` or `decidim-test:<version>` (eg: `decidim-test:0.23.1`): the above gem environment plus tooling for testing.
- `decidim-dev:latest` or `decidim-dev:<version>` (eg: `decidim-dev:0.23.1`): the above plus more configuration for running local dev environment.
- `decidim:latest` or `decidim:<version>` (eg: `decidim:0.23.1`): actual generated Decidim app to be run locally.


## Using the decidim (app) image

With this image you can run a pre-generated Decidim app:

```bash
docker run -it --rm \
  -e DATABASE_USERNAME=postgres \
  -e DATABASE_PASSWORD=postgres \
  -e DATABASE_HOST=host.docker.internal \
  -e RAILS_ENV=development \
  -p 3000:3000 \
  ghcr.io/decidim/decidim:latest
```

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

The generator image can be used in conjunction with docker-compose, and the core [decidim/decidim](https://github.com/decidim/decidim) repo already offers a [docker-compose.yml](https://github.com/decidim/decidim/blob/develop/docker-compose.yml) file (currently pointing to the Docker Hub `decidim/decidim:latest-dev` image).

It is convenient, but not absolutely mandatory to create a volume for the /usr/local/bundle folder.
