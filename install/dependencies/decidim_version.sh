#!/bin/bash

echo "───────────────────────────────────────────────"
echo "📦 What version of Decidim do you want to use?"
echo
echo "The default image is: decidim/decidim:latest"
echo
echo "You can also specify a custom image, for example:"
echo "  • decidim/decidim:0.30"
echo "  • ghcr.io/decidim/decidim:0.28"
echo "  • ghcr.io/my-org/custom-decidim:1.0.0"
echo

while true; do
  read -r -p "👉 Enter the Decidim image (or press Enter to use the default): " DECIDIM_IMAGE </dev/tty

  DECIDIM_IMAGE=${DECIDIM_IMAGE:-decidim/decidim:latest}

  echo "Trying to pull: $DECIDIM_IMAGE"

  if docker pull "$DECIDIM_IMAGE"; then
    echo "✅ Successfully pulled image: $DECIDIM_IMAGE"
    break
  else
    echo "Failed to pull image: $DECIDIM_IMAGE"
    echo "Please try again."
    echo
  fi
done
