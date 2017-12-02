#!/bin/bash

docker pull decidim/decidim:latest || true
docker pull decidim/decidim:latest-test || true
docker pull decidim/decidim:latest-dev || true
docker pull decidim/decidim:latest-deploy || true
