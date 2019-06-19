#!/bin/bash

set -e

if [[ "${CIRCLE_BRANCH}" == "master" ]]; then
  echo "$DOCKER_PASS" | docker login --username "$DOCKER_USER" --password-stdin

  docker push "decidim/decidim:$DECIDIM_VERSION-deploy"
  docker push "decidim/decidim:$DECIDIM_VERSION-dev"
  docker push "decidim/decidim:$DECIDIM_VERSION-test"
  docker push "decidim/decidim:$DECIDIM_VERSION"

  docker push decidim/decidim:latest-deploy
  docker push decidim/decidim:latest-dev
  docker push decidim/decidim:latest-test
  docker push decidim/decidim:latest
fi

if [[ "${CIRCLE_BRANCH}" =~ ^[0-9\.]+$ ]]; then
  echo "$DOCKER_PASS" | docker login --username "$DOCKER_USER" --password-stdin

  docker push "decidim/decidim:$DECIDIM_VERSION-deploy"
  docker push "decidim/decidim:$DECIDIM_VERSION-dev"
  docker push "decidim/decidim:$DECIDIM_VERSION-test"
  docker push "decidim/decidim:$DECIDIM_VERSION"
fi
