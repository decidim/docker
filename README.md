# Docker files for Decidim [![CircleCI](https://circleci.com/gh/decidim/docker.svg?style=svg)](https://circleci.com/gh/decidim/docker)

## Docker images for development.

The development image is intended to be in conjunction with docker-compose. This image includes an script that makes feasible to keep ownership of the files created inside the container for for the user used ouside it.

It is convenient, but not absolutely mandatory that you create a volume for the /usr/local/bundle folder.

## How to use it

With this docker image you can generate a new Decidim application. For instance for an application called HelloWorld:

```bash
APP_NAME=HelloWorld
docker run -it -v "$(pwd):/code" decidim/decidim ${APP_NAME}
sudo chown -R $(whoami): ${APP_NAME}
```

Then you can continue with the process detailed on [Getting Started](https://github.com/decidim/decidim/blob/master/docs/getting_started.md).

## Publish a new version

To publish a new version on [Docker Hub](https://hub.docker.com/r/decidim/decidim/) it's necessary to make a PR and change the DECIDIM_VERSION on circle-ci.yml to the last pulished version on rubygems.

CircleCI will execute automatically the bash scripts on scripts/ to build the images and publish them on Docker Hub.
