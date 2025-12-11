#!/bin/bash
set -e # exit on error

BUILD_ENV_PATH="$REPOSITORY_PATH/.env"

echo "───────────────────────────────────────────────"
echo "📦 Now we need to get some information about the instance you are building."
echo
read -r -p "What are you going to name your instance? " DECIDIM_APPLICATION_NAME </dev/tty
echo "The name of the instance is: $DECIDIM_APPLICATION_NAME"
echo
echo "Now we need to know how people will access this instance (e.g., decidim.example.org)"
read -r -p "domain: " DECIDIM_DOMAIN </dev/tty

echo "───────────────────────────────────────────────"
echo "To set up the Database we also need some information"
read -r -p "Do you have an external database already set up? [y/N] " yn </dev/tty
yn=${yn:-N}

build_local_database() {
  POSTGRES_USER="user_$(openssl rand -hex 3)"
  POSTGRES_PASSWORD="$(openssl rand -hex 18)"
  POSTGRES_DB="db_$(openssl rand -hex 3)"

  DATABASE_USER=$POSTGRES_USER
  DATABASE_PASSWORD=$POSTGRES_PASSWORD
  DATABASE_NAME=$POSTGRES_DB
  DATABASE_HOST="db"

  COMPOSE_PROFILES="db"
}

build_external_database() {
  read -r -p "Name of the database: " DATABASE_NAME </dev/tty
  read -r -p "Database user: " DATABASE_USER </dev/tty
  read -r -p "Database host (ip or domain): " DATABASE_HOST </dev/tty
  read -r -p "Database password: " DATABASE_PASSWORD </dev/tty
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

DATABASE_URL="postgres://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST/$DATABASE_NAME"

echo "───────────────────────────────────────────────"
echo "Now we have to set your SMTP server."
echo "You can check the documentation to know what to do here."
read -r -p "SMTP_USERNAME: " SMTP_USERNAME </dev/tty
read -r -p "SMTP_PASSWORD: " SMTP_PASSWORD </dev/tty
read -r -p "SMTP_ADDRESS: " SMTP_ADDRESS </dev/tty
read -r -p "SMTP_DOMAIN: " SMTP_DOMAIN </dev/tty
read -r -p "SMTP_PORT (587): " SMTP_PORT </dev/tty
SMTP_PORT=${SMTP_PORT:-587}

echo "───────────────────────────────────────────────"
echo "To start, we are going to store assets locally, in case you don't have a S3-compatible bucket."
read -r -p "Do you have an external bucket already set up? [y/N] " yn </dev/tty
yn=${yn:-N}

get_storage_keys() {
  echo "Now we are going to configure the access to the S3-compatible storage."
  echo "To learn more you can go through the Decidim documentation on https://docs.decidim.org/en/develop/services/activestorage#_amazon_s3"
  read -r -p "Access Key ID: " AWS_ACCESS_KEY_ID </dev/tty
  read -r -p "Secret Access Key: " AWS_SECRET_ACCESS_KEY </dev/tty
  read -r -p "Name of the bucket: " AWS_BUCKET </dev/tty
  read -r -p "Region of the bucket (Defaults to auto): " AWS_REGION </dev/tty
  read -r -p "Endpoint: " AWS_ENDPOINT </dev/tty

  AWS_REGION=${AWS_REGION:-auto}
}

case "$yn" in
[Yy]*)
  get_storage_keys
  ;;
*)
  STORAGE="local"
  ;;
esac

echo "Generate VAPID keys"
source "$REPOSITORY_PATH"/dependencies/generate_vapid_keys.sh

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
