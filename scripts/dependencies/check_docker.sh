#!/bin/bash

set -e

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing docker..."
  echo "Once installed it might be necessary to re-run the script so that the changes take up effect."
  echo "To do so you can run `newgrp docker`"

  # Add Docker's official GPG key:
  sudo apt update && sudo apt upgrade -y
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  sudo usermod -aG docker "${USER}"
  echo "Re-run the script after running `sudo newgrp docker`"
  exit 1
else
  echo "Docker is installed $(docker --version)"
fi

