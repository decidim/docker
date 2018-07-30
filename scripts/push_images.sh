#!/bin/bash

set -e

latest_version=$(curl https://rubygems.org/api/v1/versions/decidim/latest.json | grep -o "[0-9][0-9]*.[0-9][0-9]*.[0-9][0-9]*")
version=${DECIDIM_VERSION:-$latest_version}

if [[ "${CIRCLE_BRANCH}" == "master" ]]; then
  docker login -u "$DOCKER_USER" -p "$DOCKER_PASS"

  docker push "decidim/decidim:$version-deploy"
  docker push "decidim/decidim:$version-dev"
  docker push "decidim/decidim:$version-test"
  docker push "decidim/decidim:$version"

  docker push decidim/decidim:latest-deploy
  docker push decidim/decidim:latest-dev
  docker push decidim/decidim:latest-test
  docker push decidim/decidim:latest
fi

if [[ "${CIRCLE_BRANCH}" =~ ^[0-9\.]+$ ]]; then
  docker login -u "$DOCKER_USER" -p "$DOCKER_PASS"

  docker push "decidim/decidim:$version-deploy"
  docker push "decidim/decidim:$version-dev"
  docker push "decidim/decidim:$version-test"
  docker push "decidim/decidim:$version"
fi
