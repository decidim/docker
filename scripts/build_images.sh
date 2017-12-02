#!/bin/bash

set -e
docker build -f Dockerfile \
            --build-arg decidim_version=$DECIDIM_VERSION \
            -t decidim:${CIRCLE_SHA1} \
            --cache-from=decidim/decidim:latest .

docker build -f Dockerfile-test \
            --build-arg base_image=decidim:${CIRCLE_SHA1} \
            --build-arg decidim_version=$DECIDIM_VERSION \
            -t decidim:${CIRCLE_SHA1}-test \
            --cache-from=decidim/decidim:latest-test .

docker build -f Dockerfile-dev \
            --build-arg base_image=decidim:${CIRCLE_SHA1} \
            --build-arg decidim_version=$DECIDIM_VERSION \
            -t decidim:${CIRCLE_SHA1}-dev \
            --cache-from=decidim/decidim:latest-dev .

docker build -f Dockerfile-deploy \
            --build-arg base_image=decidim:${CIRCLE_SHA1} \
            -t decidim:${CIRCLE_SHA1}-deploy \
            --cache-from=decidim/decidim:latest-deploy .
