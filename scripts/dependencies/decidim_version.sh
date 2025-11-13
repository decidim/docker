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
read -p "👉 Enter the Decidim image (or press Enter to use the default): " DECIDIM_IMAGE </dev/tty

# Use default if none entered
DECIDIM_IMAGE=${DECIDIM_IMAGE:-decidim/decidim:latest}

docker pull "$DECIDIM_IMAGE"

echo "✅ Using Decidim image: $DECIDIM_IMAGE"
echo "───────────────────────────────────────────────"

echo "Downloading Decidim image..."

docker pull $DECIDIM_IMAGE
