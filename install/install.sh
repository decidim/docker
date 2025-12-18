#!/bin/bash
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set -e
set -u
set -o pipefail

echo -e "***********************************************************************"
echo -e "* 🚀 Welcome to Decidim Installation Script!                          *"
echo -e "*                                                                     *"
echo -e "* This script will install Decidim on this machine and guide you      *"
echo -e "* through the complete configuration process.                         *"
echo -e "*                                                                     *"
echo -e "* You'll need to provide:                                             *"
echo -e "*   • Instance name and domain                                        *"
echo -e "*   • Database configuration (local or external)                      *"
echo -e "*   • SMTP server settings for emails                                 *"
echo -e "*   • File storage settings (local or S3)                             *"
echo -e "*                                                                     *"
echo -e "* 💡 All dependencies (Docker, etc.) will be installed for you        *"
echo -e "*                                                                     *"
echo -e "* ⚠️ For production use, review security settings and documentation.  *"
echo -e "*                                                                     *"
echo -e "***********************************************************************"

REPOSITORY_PATH=${DECIDIM_PATH:-/opt/decidim}
REPOSITORY_URL="https://github.com/decidim/docker.git"
REPOSITORY_BRANCH="feat/decidim_install"

export REPOSITORY_URL
export REPOSITORY_BRANCH

echo "📁 Installation directory: $REPOSITORY_PATH"

trap 'echo "❌ Error occurred at line $LINENO. You can re-run this script to restart the installation."' ERR

if [ ! -d "$REPOSITORY_PATH" ]; then
  echo "📁 Creating installation directory: $REPOSITORY_PATH"
  if ! sudo mkdir -p "$REPOSITORY_PATH"; then
    echo "❌ Failed to create directory $REPOSITORY_PATH"
    exit 1
  fi
  if ! sudo chown "$USER":"$USER" "$REPOSITORY_PATH"; then
    echo "❌ Failed to set ownership of $REPOSITORY_PATH"
    exit 1
  fi
fi

TMP="/tmp/decidim-docker-files"
if [ ! -d "$TMP" ]; then
  mkdir "$TMP"
fi

echo "📥 Downloading the installation necessary files."
curl -L -o "$TMP/deploy.zip" "$REPOSITORY_URL/releases/download/latest/deploy.zip"

echo "📦 Installing unzip package..."
if ! (sudo apt update && sudo apt install unzip -y); then
  echo "❌ Failed to install unzip package"
  exit 1
fi

echo "📂 Extracting files to $REPOSITORY_PATH..."
if [ ! -d "$REPOSITORY_PATH" ]; then
  if ! unzip -u "$TMP/deploy.zip" -d "$REPOSITORY_PATH" </dev/tty; then
    echo "❌ Failed to extract files to $REPOSITORY_PATH"
    exit 1
  fi
else
  if ! unzip "$TMP/deploy.zip" -d "$REPOSITORY_PATH" </dev/tty; then
    echo "❌ Failed to extract files to $REPOSITORY_PATH"
    exit 1
  fi
fi

if ! cd "$REPOSITORY_PATH"; then
  echo "❌ Failed to change to directory $REPOSITORY_PATH"
  exit 1
fi

echo "🔍 Checking the OS version..."
# shellcheck disable=SC1091
source "./dependencies/os_version.sh"

# Check if docker is installed, if not install it
echo "🐳 Checking if Docker is installed..."
# shellcheck disable=SC1091
source "./dependencies/check_docker.sh"

# Checking which Decidim version does the user want
echo "📦 Checking the Decidim version to use..."
# shellcheck disable=SC1091
source "./dependencies/decidim_version.sh"

# Open necessary ports
echo "🔌 Opening necessary server ports..."
# shellcheck disable=SC1091
source "./dependencies/open_ports.sh"

# Build environment variables
# shellcheck disable=SC1091
source "./dependencies/build_env.sh"

echo "🔧 Building dependencies..."
# shellcheck disable=SC1091
source "./dependencies/generate_gemfile.sh"

# Start decidim
echo "🚀 Starting Decidim..."
# shellcheck disable=SC1091
source "./up.sh"

# Generate the system admin
# shellcheck disable=SC1091
source "./dependencies/create_system_admin.sh"

# Close up script
echo "───────────────────────────────────────────────"
echo "🎉 Installation Complete!"
echo
echo "📋 Next Steps:"
echo "   1. Access your admin panel: https://${DECIDIM_DOMAIN}/system"
echo "   2. Log in with the system admin credentials you just created"
echo "   3. Configure your organization and start participating!"
echo
echo "💡 Important Environment Files:"
echo "   • .env - Contains all your configuration (database, SMTP, etc.)"
echo "   • docker-compose.yml - Defines your services"
echo
echo "🔧 Useful Commands:"
echo "   • View logs: docker compose logs -f"
echo "   • Stop services: docker compose down"
echo "   • Restart services: docker compose restart"
echo
echo "📚 Documentation: https://docs.decidim.org"
echo "🐛 Issues: https://github.com/decidim/decidim/issues"
echo "🐛 Installation Issues: https://github.com/decidim/docker/issues"
echo
echo "Have fun using Decidim! 🗳️"
