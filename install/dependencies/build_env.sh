#!/bin/bash
set -e
set -u
set -o pipefail

BUILD_ENV_PATH="$REPOSITORY_PATH/.env"

if [ -z "${REPOSITORY_PATH:-}" ]; then
  echo "❌ Error: REPOSITORY_PATH is not set"
  exit 1
fi

echo "───────────────────────────────────────────────"
echo "🔧 Environment Configuration Phase"
echo "   We'll now collect all the information needed to configure your Decidim instance."
echo "   All responses will be saved in a .env file that you can edit later."
echo
echo "📝 Information we'll collect:"
echo "   • Instance details (name, domain)"
echo "   • Database settings (local PostgreSQL or external)"
echo "   • Email configuration (SMTP server)"
echo "   • File storage (local filesystem or S3 bucket)"
echo "   • Security keys (auto-generated)"
echo
echo "💡 Don't worry if you don't have all the details ready!"
echo "   You can always modify the .env file after installation."
echo
echo "Press Enter to continue..."
read -r </dev/tty

echo "───────────────────────────────────────────────"
echo "📦 Now we need to get some information about the instance you are building."
echo
echo "💡 The application name will be displayed throughout the interface"
echo "   and used in email subjects. Make it descriptive!"
echo
read -r -p "What is the name of your organization? (For example: Decidim Barcelona)" DECIDIM_APPLICATION_NAME </dev/tty
echo "✅ The name of the instance is: $DECIDIM_APPLICATION_NAME"
echo
echo "💡 This is the domain where users will access your Decidim instance."
echo "   Make sure you have DNS configured for this domain."
echo "   Example: decidim.example.org"
echo
read -r -p "domain: " DECIDIM_DOMAIN </dev/tty
echo "✅ Your instance will be accessible at: https://$DECIDIM_DOMAIN"

echo "───────────────────────────────────────────────"
echo "🗄️  Database Configuration"
echo "   We need to set up your Decidim database."
echo "   💡 You can use our built-in PostgreSQL database (recommended for beginners)"
echo "      or connect to an existing external database."
echo
read -r -p "Do you have an external database already set up? [y/N] " yn </dev/tty
yn=${yn:-N}

build_local_database() {
  echo "🏗️  Creating local database configuration..."

  POSTGRES_USER="user_$(openssl rand -hex 3)"
  POSTGRES_PASSWORD="$(openssl rand -hex 18)"
  POSTGRES_DB="db_$(openssl rand -hex 3)"

  DATABASE_USER=$POSTGRES_USER
  DATABASE_PASSWORD=$POSTGRES_PASSWORD
  DATABASE_NAME=$POSTGRES_DB
  DATABASE_HOST="db"

  COMPOSE_PROFILES="db"

  echo "✅ Local database will be created with these credentials:"
  echo "   Database: $DATABASE_NAME"
  echo "   User: $DATABASE_USER"
  echo "   Host: $DATABASE_HOST"
  echo "   💡 Password will be securely stored in .env file"
}

build_external_database() {
  echo "📋 External Database Configuration"
  echo "   Please provide your external database details:"
  echo "   💡 Make sure your database server allows connections from this machine."
  echo

  while [ -z "${DATABASE_NAME:-}" ]; do
    read -r -p "Name of the database: " DATABASE_NAME </dev/tty
    if [ -z "$DATABASE_NAME" ]; then
      echo "❌ Database name cannot be empty"
    fi
  done

  while [ -z "${DATABASE_USER:-}" ]; do
    read -r -p "Database user: " DATABASE_USER </dev/tty
    if [ -z "$DATABASE_USER" ]; then
      echo "❌ Database user cannot be empty"
    fi
  done

  while [ -z "${DATABASE_HOST:-}" ]; do
    read -r -p "Database host (ip or domain): " DATABASE_HOST </dev/tty
    if [ -z "$DATABASE_HOST" ]; then
      echo "❌ Database host cannot be empty"
    fi
  done

  while [ -z "${DATABASE_PASSWORD:-}" ]; do
    read -r -p "Database password: " DATABASE_PASSWORD </dev/tty
    if [ -z "$DATABASE_PASSWORD" ]; then
      echo "❌ Database password cannot be empty"
    fi
  done

  echo "✅ External database configured: postgres://$DATABASE_USER:***@$DATABASE_HOST/$DATABASE_NAME"
}

case $yn in
[Yy]*)
  EXTERNAL_DATABASE=true
  build_external_database
  ;;
[Nn]*)
  EXTERNAL_DATABASE=false
  build_local_database
  ;;
esac

export EXTERNAL_DATABASE

DATABASE_URL="postgres://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST/$DATABASE_NAME"

echo "───────────────────────────────────────────────"
echo "📧 Email Configuration (SMTP)"
echo "   Decidim needs to send emails for notifications, user registration, etc."
echo "   💡 You'll need an SMTP server. "
echo "   🔗 Documentation: https://docs.decidim.org/en/develop/services/smtp.html"
echo
read -r -p "SMTP_USERNAME: " SMTP_USERNAME </dev/tty
read -r -p "SMTP_PASSWORD: " SMTP_PASSWORD </dev/tty
read -r -p "SMTP_ADDRESS (e.g., smtp.gmail.com): " SMTP_ADDRESS </dev/tty
read -r -p "SMTP_DOMAIN (usually same as your domain): " SMTP_DOMAIN </dev/tty
read -r -p "SMTP_PORT (587 for TLS - default, 465 for SSL): " SMTP_PORT </dev/tty
SMTP_PORT=${SMTP_PORT:-587}

echo "───────────────────────────────────────────────"
echo "📁 File Storage Configuration"
echo "   Decidim stores user uploads, images, and documents."
echo "   💡 For production, we recommend S3-compatible storage."
echo "      But we also support local storage."
echo
read -r -p "Do you have an external S3-compatible bucket already set up? [y/N] " yn </dev/tty
yn=${yn:-N}

get_storage_keys() {
  echo "🗂️  S3-compatible Storage Configuration"
  echo "   Please provide your S3 storage details:"
  echo "   💡 Supported providers: AWS S3, Cloudflare R2, etc."
  echo "   🔗 Documentation: https://docs.decidim.org/en/develop/services/activestorage"
  echo
  read -r -p "Access Key ID: " AWS_ACCESS_KEY_ID </dev/tty
  read -r -p "Secret Access Key: " AWS_SECRET_ACCESS_KEY </dev/tty
  read -r -p "Name of the bucket: " AWS_BUCKET </dev/tty
  read -r -p "Region of the bucket (Defaults to auto): " AWS_REGION </dev/tty
  read -r -p "Endpoint (required for non-AWS S3): " AWS_ENDPOINT </dev/tty

  AWS_REGION=${AWS_REGION:-auto}

  echo "✅ S3 storage configured for bucket: $AWS_BUCKET"
}

case "$yn" in
[Yy]*)
  get_storage_keys
  ;;
*)
  STORAGE="local"
  ;;
esac

echo "───────────────────────────────────────────────"
echo "🔐 Security Configuration"
echo "   Generating VAPID keys for secure push notifications..."
# shellcheck disable=SC1091
source "./dependencies/generate_vapid_keys.sh"

echo "───────────────────────────────────────────────"
echo "Maps and Geocoding Configuration"
echo "   In order for the maps inside the application to work, we have to configure the service"
echo "   🔗 Documentation: https://docs.decidim.org/en/develop/services/maps"
echo
echo "   Currently, this installation process only handles HERE Maps."
echo "   You will need to provide the API KEY provided by HERE."
echo "   This will be saved in the .env file, but you'll be always able to change it."
read -r -p "HERE API KEY: " MAPS_API_KEY </dev/tty
MAPS_API_PROVIDER=${MAPS_API_PROIVDER=-here}

echo "───────────────────────────────────────────────"
echo "✍️ Now we are going to create the .env file."

if [ -f "$BUILD_ENV_PATH" ]; then
  echo "❌ Failing: .env file already exists."
  read -r -p "Do you want to delete the .env file and create a new one? You can make a back-up of it before answering. [Y/n]" yn </dev/tty
  yn=${yn:-Y}

  case $yn in
  [Yy]*)
    echo "Deleting .env file."
    rm "$BUILD_ENV_PATH"
    ;;
  [Nn]*)
    echo "Can't continue without a new .env file"
    exit 1
    ;;
  esac
fi

# Variable to handle the let's encrypt email.
CERTIFICATE_EMAIL="${CERTIFICATE_EMAIL:-postmaster@${DECIDIM_DOMAIN}}"

echo "───────────────────────────────────────────────"
echo "🎯 Final Configuration Summary:"
echo "   Instance Name: $DECIDIM_APPLICATION_NAME"
echo "   Domain: https://$DECIDIM_DOMAIN"
echo "   Database: $DATABASE_NAME (host: $DATABASE_HOST)"
echo "   Storage: $([ "$STORAGE" = 'local' ] && echo 'Local filesystem' || echo 'S3-compatible bucket')"
echo "   Certificate Email: $CERTIFICATE_EMAIL"
echo
echo "💡 All configuration will be saved to .env file"
echo "   You can modify these values later if needed."
echo
echo "✅ Writing the environment variables to .env file..."
cat >"$BUILD_ENV_PATH" <<EOF
BUNDLE_GEMFILE="Gemfile.wrapper"
DECIDIM_IMAGE=$DECIDIM_IMAGE
DECIDIM_APPLICATION_NAME="$DECIDIM_APPLICATION_NAME"
DECIDIM_DOMAIN="$DECIDIM_DOMAIN"

SECRET_KEY_BASE=$(openssl rand -hex 64)

DATABASE_NAME="$DATABASE_NAME"
DATABASE_USER="$DATABASE_USER"
DATABASE_HOST="$DATABASE_HOST"
DATABASE_PASSWORD="$DATABASE_PASSWORD"
DATABASE_URL="$DATABASE_URL"

SMTP_USERNAME="$SMTP_USERNAME"
SMTP_PASSWORD="$SMTP_PASSWORD"
SMTP_ADDRESS="$SMTP_ADDRESS"
SMTP_DOMAIN="$SMTP_DOMAIN"
SMTP_PORT="$SMTP_PORT"

MAPS_API_PROVIDER="$MAPS_API_PROVIDER"
MAPS_API_KEY="$MAPS_API_KEY"

REDIS_URL="redis://decidim_cache:6379"

VAPID_PUBLIC_KEY="$VAPID_PUBLIC_KEY"
VAPID_PRIVATE_KEY="$VAPID_PRIVATE_KEY"

CERTIFICATE_EMAIL="$CERTIFICATE_EMAIL"

COMPOSE_PROFILES=$COMPOSE_PROFILES

EOF

if [ "$STORAGE" != 'local' ]; then
  cat >>"$BUILD_ENV_PATH" <<EOF
  AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
  AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
  AWS_BUCKET="$AWS_BUCKET"
  AWS_REGION="$AWS_REGION"
  AWS_ENDPOINT="$AWS_ENDPOINT"
EOF
fi

echo "✅ All environment variables saved to $BUILD_ENV_PATH successfully!"
