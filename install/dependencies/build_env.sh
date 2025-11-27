#!/bin/bash
set -e # exit on error

BUILD_ENV_PATH="$REPOSITORY_PATH/.env"

echo "───────────────────────────────────────────────"
echo "📦 Now we need to get some information about the instance you are building."
echo
read -p "What are you going to name your instance? " DECIDIM_APPLICATION_NAME </dev/tty
echo "The name of the instance is: $DECIDIM_APPLICATION_NAME"
echo
echo "Now we need to know how people will access this instance (e.g., decidim.example.org)"
read -p "domain: " DECIDIM_DOMAIN </dev/tty

echo "───────────────────────────────────────────────"
echo "To set up the Database we also need some information"
read -p "Do you have an external database already set up? [y/N] " yn </dev/tty
yn=${yn:-N}

build_local_database() {
  POSTGRES_USER="user_$(openssl rand -hex 3)"
  POSTGRES_PASSWORD="$(openssl rand -hex 18)"
  POSTGRES_DB="db_$(openssl rand -hex 3)"

  DATABASE_USER=$POSTGRES_USER
  DATABASE_PASSWORD=$POSTGRES_PASSWORD
  DATABASE_NAME=$POSTGRES_DB
  DATABASE_HOST="db"
}

build_external_database() {
  read -p "Name of the database: " DATABASE_NAME </dev/tty
  read -p "Database user: " DATABASE_USER </dev/tty
  read -p "Database host (ip or domain): " DATABASE_HOST </dev/tty
  read -p "Database password: " DATABASE_PASSWORD </dev/tty
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
read -p "SMTP_USERNAME: " SMTP_USERNAME </dev/tty
read -p "SMTP_PASSWORD: " SMTP_PASSWORD </dev/tty
read -p "SMTP_ADDRESS: " SMTP_ADDRESS </dev/tty
read -p "SMTP_DOMAIN: " SMTP_DOMAIN </dev/tty

echo "───────────────────────────────────────────────"
echo "To start, we are going to store assets locally, in case you don't have a S3-compatible bucket."
read -p "Do you have an external bucket already set up? [y/N] " yn </dev/tty
yn=${yn:-N}

get_storage_keys() {
  echo "Now we are going to configure the access to the S3-compatible storage."
  echo "To learn more you can go through the Decidim documentation on https://docs.decidim.org/en/develop/services/activestorage#_amazon_s3"
  read -p "Access Key ID: " AWS_ACCESS_KEY_ID </dev/tty
  read -p "Secret Access Key: " AWS_SECRET_ACCESS_KEY </dev/tty
  read -p "Name of the bucket: " AWS_BUCKET </dev/tty
  read -p "Region of the bucket (Defaults to auto): " AWS_REGION </dev/tty
  read -p "Endpoint: " AWS_ENDPOINT </dev/tty

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
source $REPOSITORY_PATH/dependencies/generate_vapid_keys.sh

if [ -f .env ]; then
  echo "❌ Failing: .env file already exists."
  read -p "Do you want to delete the .env file and create a new one? You can make a back-up of it before answering. [Y/n]" yn </dev/tty
  yn=${yn:-Y}

  case $yn in
    [Yy]*) 
      echo "Deleting .env file."
      rm .env
      ;;
    [Nn]*)
      echo "Can't continue without a new .env file"
      exit 1;
      ;;
  esac
fi

echo "✅ Writing the environment variables to .env file..."
cat >.env <<EOF
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

REDIS_URL="redis://decidim_cache:6379"

VAPID_PUBLIC_KEY="$VAPID_PUBLIC_KEY"
VAPID_PRIVATE_KEY="$VAPID_PRIVATE_KEY"
EOF

if [ $STORAGE != 'local' ]; then
  cat >>.env <<EOF
  AWS_ACCESS_KEY_ID="$AWS_SECRET_ACCESS_KEY"
  AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
  AWS_BUCKET="$AWS_SECRET_ACCESS_KEY"
  AWS_REGION="$AWS_SECRET_ACCESS_KEY"
  AWS_ENDPOINT="$AWS_SECRET_ACCESS_KEY"
fi


echo "✅ All environment variables saved to .env successfully!"
