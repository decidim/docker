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

echo -e "***********************************************************************"
echo -e "* This script will try to install Decidim on this machine.            *"
echo -e "* Take into account that it will ask for some information that        *"
echo -e "* you will have to provide. Also it will take care of installing      *"
echo -e "* all necessary dependencies, such as *docker*, *git*, etc.           *"
echo -e "*                                                                     *"
echo -e "* You will be guided throughout the script and will be able to        *"
echo -e "* stop it and restart it if necessary.                                *"
echo -e "*                                                                     *"
echo -e "* It's not in a production-ready state. There's not guarantee         *"
echo -e "* and it's up to you to take care of your systems.                    *"
echo -e "*                                                                     *"
echo -e "***********************************************************************"

REPOSITORY_PATH=${DECIDIM_PATH:-/opt/decidim}
REPOSITORY_URL="https://github.com/decidim/docker.git"
REPOSITORY_BRANCH="feat/decidim_install"

echo $REPOSITORY_PATH

set -e

trap "You can re-run this script to restart the installation", ERR

if [ ! -d "$REPOSITORY_PATH" ]; then
  sudo mkdir -p "$REPOSITORY_PATH"
  sudo chown "$USER":"$USER" "$REPOSITORY_PATH"
fi

TMP=/tmp/decidim-docker-files
if [ ! -d $TMP ]; then
  mkdir $TMP
fi

echo "Downloading the installation necessary files."
#curl -L -o "$TMP/deploy.tar.gz" "$REPOSITORY_URL/releases/latest/download/deploy_bundle.zip"
cp /tmp/decidim-docker/install/deploy.zip $TMP/deploy.zip
sudo apt install unzip -y

if [ ! -d $REPOSITORY_PATH ]; then
  unzip -f $TMP/deploy.zip -d $REPOSITORY_PATH </dev/tty
else
  unzip $TMP/deploy.zip -d $REPOSITORY_PATH </dev/tty
fi

cd $REPOSITORY_PATH

echo "Checking the OS version"
source $REPOSITORY_PATH/dependencies/os_version.sh

# Check if docker is installed, if not install it
echo "Checking if docker is installed. If not install it."
source $REPOSITORY_PATH/dependencies/check_docker.sh

# Checking which Decidim version does the user want
echo "Checking the Decidim version to use."
source $REPOSITORY_PATH/dependencies/decidim_version.sh

# Open necessary ports
echo "Openning necessary server ports."
source $REPOSITORY_PATH/dependencies/open_ports.sh

# Build environment variables
echo "Asking for necessary variables."
source $REPOSITORY_PATH/dependencies/build_env.sh

echo "Building dependencies"
source $REPOSITORY_PATH/dependencies/generate_gemfile.sh

# Start decidim
echo "Starting Decidim..."
source $REPOSITORY_PATH/up.sh

# Generate the system admin
source $REPOSITORY_PATH/dependencies/create_system_admin.sh

# Close up script
echo "Now you should be able to access ${DECIDIM_DOMAIN}/system and log in with the system you already created."
echo "Have fun using Decidim!"
