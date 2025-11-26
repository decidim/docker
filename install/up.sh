#!/bin/bash

composes="-f app.yml -f traefik.yml -f cache.yml -f worker.yml "

if ! $EXTERNAL_DATABASE; then
  composes+=" -f db.yml"
fi

if [ "$STORAGE" == 'local' ]; then
  composes+=" -f storage.yml"
fi

sudo docker compose --env-file .env ${composes} up
