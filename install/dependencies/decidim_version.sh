#!/bin/bash

echo "───────────────────────────────────────────────"
echo "📦 Decidim version"
echo
echo "💡 About Decidim versions:"
echo "   • latest - Most recent stable release (recommended)"
echo "   • Custom images - Your own modified Decidim builds"
echo
echo "If you want, later on you can modify the 'docker-compose.yml' to change the Decidim version."
echo
echo "Default image: decidim/decidim:latest"
echo

while true; do
  read -r -p "👉 Press enter to continue with the download of the Decidim image" </dev/tty

  DECIDIM_IMAGE=${DECIDIM_IMAGE:-decidim/decidim:latest}

  echo "Attempting to pull: $DECIDIM_IMAGE"

  if docker pull "$DECIDIM_IMAGE"; then
    echo "✅ Successfully pulled image: $DECIDIM_IMAGE"
    break
  else
    echo "❌ Failed to pull image: $DECIDIM_IMAGE"
    echo "Please try again."
    echo
  fi
done
