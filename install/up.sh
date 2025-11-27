#!/bin/bash

composes="-f app.yml -f traefik.yml -f cache.yml -f worker.yml "

if ! $EXTERNAL_DATABASE; then
  composes+=" -f db.yml"
fi

if [ "$STORAGE" == 'local' ]; then
  composes+=" -f storage.yml"
fi

echo "Starting containers..."
docker compose --env-file .env up -d

docker compose logs --tail=20
