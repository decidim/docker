#!/bin/bash
set -e
set -u
set -o pipefail

ENV_FILE="${REPOSITORY_PATH}/.env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Error: .env file not found at $ENV_FILE"
  echo "   Please run the installation script first or create the .env file manually."
  exit 1
fi

echo "🚀 Starting Decidim containers..."

docker compose --env-file "$ENV_FILE" up -d

echo "📋 Showing recent container logs..."
docker compose logs --tail=30

echo "✅ Containers started successfully!"
echo "🔍 You can monitor logs with: docker compose logs -f"
