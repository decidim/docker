#!/bin/bash

set -xe
echo "Generating VAPID keys"
output=$(docker run --rm \
  "$DECIDIM_IMAGE" \
  bin/rails decidim:pwa:generate_vapid_keys)

echo $output

VAPID_PUBLIC_KEY=$(echo "$output" | grep 'VAPID_PUBLIC_KEY' | cut -d'=' -f2)
VAPID_PRIVATE_KEY=$(echo "$output" | grep 'VAPID_PRIVATE_KEY' | cut -d'=' -f2)
