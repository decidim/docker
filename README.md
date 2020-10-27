# Docker images for Decidim 

There are two official images available for Decidim on Github Packages: `decidim` and `decidim-generator`.

The `decidim` image is a dockerized Decidim app with standard core modules. It can be used for quickly spinning up a local instance and kick the tires, or for deployment if all you need are the core modules.

The `decidim-generator` image is a base environment with all you need to generate a new Decidim app locally. It is also the base image from which the `decidim` image is built.

## Using the decidim (app) image

With this image you can run a pre-generated Decidim app:

```bash
docker run -it --rm \
  -e DATABASE_USERNAME=postgres \
  -e DATABASE_PASSWORD=postgres \
  -e DATABASE_HOST=host.docker.internal \
  -e RAILS_ENV=development \
  -p 3000:3000 \
  docker.pkg.github.com/decidim/docker/decidim:latest
```

```bash
docker run -it --rm \
  -e DATABASE_URL="postgres://user:pass@postgres-host/decidim-production-db" \
  -p 3000:3000 \
  docker.pkg.github.com/decidim/docker/decidim:latest
```

## Using the decidim-generator image

With this image you can generate a new Decidim application:

```bash
APP_NAME=HelloWorld
IMAGE=docker.pkg.github.com/decidim/docker/decidim-generator:latest
docker run -it -v "$(pwd):/code" ${IMAGE} ${APP_NAME}
sudo chown -R $(whoami): ${APP_NAME}
```

From here on you can follow the steps on the [Getting Started](https://github.com/decidim/decidim/blob/master/docs/getting_started.md) guide.

### Using decidim-generator with docker-compose

The generator image can be used in conjunction with docker-compose, and the core [decidim/decidim](https://github.com/decidim/decidim) repo already offers a [docker-compose.yml](https://github.com/decidim/decidim/blob/develop/docker-compose.yml) file (currently pointing to the Docker Hub `decidim/decidim:latest-dev` image).

It is convenient, but not absolutely mandatory to create a volume for the /usr/local/bundle folder.

## Docker Hub images

We're in the process of adopting Github Actions for our automated image build and publishing, and while that flow currently only publishes to Github Packages, there's another flow on circleci publishing images to Docker Hub.

We plan to phase out the circleci flow soon, and publish to Docker Hub with Github Actions as well.

Meanwhile, be aware that Docker Hub and Github Package images are gradually diverging.

