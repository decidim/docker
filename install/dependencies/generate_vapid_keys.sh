#!/bin/bash

set -e
set -u
set -o pipefail

echo "🔐 Generating VAPID keys..."

# Check if DECIDIM_IMAGE is set
if [ -z "${DECIDIM_IMAGE:-}" ]; then
  echo "❌ Error: DECIDIM_IMAGE is not set"
  exit 1
fi

output=$(docker run --rm \
  "$DECIDIM_IMAGE" \
  bin/rails decidim:pwa:generate_vapid_keys)

echo "✅ The VAPID keys have been generated correctly"

VAPID_PUBLIC_KEY=$(echo "$output" | grep 'VAPID_PUBLIC_KEY' | cut -d'=' -f2)
VAPID_PRIVATE_KEY=$(echo "$output" | grep 'VAPID_PRIVATE_KEY' | cut -d'=' -f2)

# Export the keys for use by calling script
export VAPID_PUBLIC_KEY
export VAPID_PRIVATE_KEY

echo "🔑 Keys successfully extracted"
