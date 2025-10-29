#!/bin/bash

set -e

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing docker..."
  echo "Once installed it might be necessary to re-run the script so that the changes take up effect."
  echo "To do so you can run `newgrp docker`"

  curl -fsSL https://get.docker.com | bash

  sudo usermod -aG docker "${USER}"
  echo "Re-run the script after running `sudo newgrp docker`"
  exit 1
else
  echo "Docker is installed $(docker --version)"
fi

