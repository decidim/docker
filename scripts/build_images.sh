#!/bin/bash

set -ex

sha1=${CIRCLE_SHA1:-latest}
latest_version=$(curl https://rubygems.org/api/v1/versions/decidim/latest.json | grep -o "[0-9][0-9]*.[0-9][0-9]*.[0-9][0-9]*")
version=${DECIDIM_VERSION:-$latest_version}
extra_args=("$@")

docker build --file Dockerfile \
             --build-arg "decidim_version=$version" \
             --tag "decidim/decidim:$sha1" \
             "${extra_args[@]}" .

docker build --file Dockerfile-test \
             --build-arg "base_image=decidim/decidim:$sha1" \
             --build-arg "decidim_version=$version" \
             --tag "decidim/decidim:$sha1-test" \
             "${extra_args[@]}" .

docker build --file Dockerfile-dev \
             --build-arg "base_image=decidim/decidim:$sha1-test" \
             --tag "decidim/decidim:$sha1-dev" \
             "${extra_args[@]}" .

docker build --file Dockerfile-deploy \
             --build-arg "base_image=decidim/decidim:$sha1" \
             --tag "decidim/decidim:$sha1-deploy" \
             "${extra_args[@]}" .
