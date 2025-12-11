#!/bin/bash

echo "Starting containers..."
docker compose --env-file .env up -d

docker compose logs --tail=20

echo "Containers started successfully."
