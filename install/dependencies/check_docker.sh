#!/bin/bash

set -e
set -u
set -o pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "🐳 Docker not found. Installing Docker..."
  echo "⚠️  After installation, you'll need to re-run this script for changes to take effect."
  echo "💡 You can run 'newgrp docker' to activate Docker group membership."

  if ! curl -fsSL https://get.docker.com | bash; then
    echo "❌ Failed to install Docker"
    exit 1
  fi

  if ! sudo usermod -aG docker "${USER}"; then
    echo "❌ Failed to add user to Docker group"
    exit 1
  fi
  
  echo ""
  echo "🔄 Docker installation completed!"
  echo "📋 Next steps:"
  echo "   1. Log out and log back in, OR run: 'newgrp docker'"
  echo "   2. Re-run this installation script"
  echo ""
  echo "⏹️  Exiting for user session refresh..."
  exit 1
else
  echo "✅ Docker is installed: $(docker --version)"
  
  # Check if user can run docker commands
  if ! docker info >/dev/null 2>&1; then
    echo "⚠️  Docker is installed but current user cannot run Docker commands."
    echo "💡 Try running: 'newgrp docker' or log out and log back in."
    echo "   If that doesn't work, you may need to: 'sudo usermod -aG docker \$USER'"
    exit 1
  fi
  
  echo "✅ Docker is accessible for current user"
fi
