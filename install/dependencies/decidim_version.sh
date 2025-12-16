#!/bin/bash

echo "───────────────────────────────────────────────"
echo "📦 Choose Your Decidim Version"
echo
echo "💡 About Decidim versions:"
echo "   • latest - Most recent stable release (recommended)"
echo "   • 0.30, 0.28, etc. - Specific stable versions"
echo "   • Custom images - Your own modified Decidim builds"
echo
echo "Default image: decidim/decidim:latest"
echo
echo "Example options:"
echo "  • decidim/decidim:latest (official stable)"
echo "  • decidim/decidim:0.30 (specific version)"
echo "  • ghcr.io/decidim/decidim:0.28 (GitHub Container Registry)"
echo "  • ghcr.io/my-org/custom-decidim:1.0.0 (your custom build)"
echo
echo "🔍 Want to see available versions? Check: https://hub.docker.com/r/decidim/decidim/tags"
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
