#!/bin/bash

set -ex

sha1=${CIRCLE_SHA1:-latest}
latest_version=$(curl https://rubygems.org/api/v1/versions/decidim/latest.json | grep -o "[0-9][0-9]*.[0-9][0-9]*.[0-9][0-9]*")
version=${DECIDIM_VERSION:-$latest_version}
extra_args=("$@")

docker build -f Dockerfile \
            --build-arg "decidim_version=$version" \
            -t "decidim/decidim:$sha1" \
            --cache-from=decidim/decidim:latest \
            "${extra_args[@]}" .

docker build -f Dockerfile-test \
            --build-arg "base_image=decidim/decidim:$sha1" \
            --build-arg "decidim_version=$version" \
            -t "decidim/decidim:$sha1-test" \
            --cache-from=decidim/decidim:latest-test \
            "${extra_args[@]}" .

docker build -f Dockerfile-dev \
            --build-arg "base_image=decidim/decidim:$sha1-test" \
            -t "decidim/decidim:$sha1-dev" \
            --cache-from=decidim/decidim:latest-dev \
            "${extra_args[@]}" .

docker build -f Dockerfile-deploy \
            --build-arg "base_image=decidim/decidim:$sha1" \
            -t "decidim/decidim:$sha1-deploy" \
            --cache-from=decidim/decidim:latest-deploy \
            "${extra_args[@]}" .
