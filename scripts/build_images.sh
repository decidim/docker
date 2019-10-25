#!/bin/bash

set -ex

sha1=${CIRCLE_SHA1:-latest}
latest_version=$(curl https://rubygems.org/api/v1/versions/decidim/latest.json | grep -o "[0-9][0-9]*.[0-9][0-9]*.[0-9][0-9]*")
version=${DECIDIM_VERSION:-$latest_version}
extra_args=("$@")

docker build --file Dockerfile \
             --build-arg "decidim_version=$version" \
             --tag "decidim/decidim:$sha1" \
             --tag "decidim/decidim:$version" \
             --tag "decidim/decidim:latest" \
             --no-cache \
             "${extra_args[@]}" .

docker build --file Dockerfile-test \
             --build-arg "base_image=decidim/decidim:$sha1" \
             --build-arg "decidim_version=$version" \
             --tag "decidim/decidim:$sha1-test" \
             --tag "decidim/decidim:$version-test" \
             --tag "decidim/decidim:latest-test" \
             --no-cache \
             "${extra_args[@]}" .

docker build --file Dockerfile-dev \
             --build-arg "base_image=decidim/decidim:$sha1-test" \
             --tag "decidim/decidim:$sha1-dev" \
             --tag "decidim/decidim:$version-dev" \
             --tag "decidim/decidim:latest-dev" \
             --no-cache \
             "${extra_args[@]}" .

docker build --file Dockerfile-deploy \
             --build-arg "base_image=decidim/decidim:$sha1" \
             --tag "decidim/decidim:$sha1-deploy" \
             --tag "decidim/decidim:$version-deploy" \
             --tag "decidim/decidim:latest-deploy" \
             --no-cache \
             "${extra_args[@]}" .
