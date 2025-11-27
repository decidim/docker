#!/bin/bash

generate_system_admin() {
  docker exec -ti \
    decidim \
    bin/rails decidim_system:create_admin </dev/tty
}

if [ -z $EXTERNAL_DATABASE ]; then
  echo "Checking if database is already running"
  until docker ps --filter "name=decidim-db" --filter "status=running" --quiet; do
    echo "Container not running yet..."
    sleep 2
  done
fi

generate_system_admin

if [ $? -eq 1 ]; then
  echo "Seems like there was a problem. Try again."
  echo "Just execute \"docker exec -ti decidim bin/rails decidim_system_create_admin\""
fi
