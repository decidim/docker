#!/bin/bash
set -e
set -u
set -o pipefail

generate_system_admin() {
  # docker exec -ti \
  #   decidim \
  #   bin/rails decidim_system:create_admin </dev/tty
  read -r -p "email: " SYSTEM_EMAIL </dev/tty
  SYSTEM_PASSSWORD="$(openssl rand -hex 12)"

  docker exec -ti \
    decidim \
    bin/rails runner "Decidim::System::Admin.create(email: '${SYSTEM_ADMIN}', password: '${SYSTEM_PASSWORD}', password_confirmation: '${SYSTEM_PASSWORD}')"
}

if [ -z "$EXTERNAL_DATABASE" ]; then
  echo "Checking if database is already running"
  until docker ps --filter "name=decidim-db" --filter "status=running" --quiet; do
    echo "Container not running yet..."
    sleep 2
  done
fi

# Simple health check for Rails server
until docker exec decidim curl -s http://localhost:3000/up >/dev/null; do
  echo "Waiting for Rails server to start..."
  sleep 10
done

echo "Container is running correctly... Now we are going to create the system admin."

generate_system_admin

if [ $? -eq 1 ]; then
  echo "❌ Seems like there was a problem creating the system admin."
  echo
  echo "🔧 Troubleshooting:"
  echo "   • Try running the command manually:"
  echo "     docker exec -ti decidim bin/rails decidim_system:create_admin"
  echo "   • Review the logs for any errors:"
  echo "     docker compose logs decidim"
else
  echo "✅ System administrator created successfully!"
  echo "Your password to access is: ${SYSTEM_PASSSWORD}"
  echo "📍 You can now access the admin panel at: https://${DECIDIM_DOMAIN}/system"
fi
