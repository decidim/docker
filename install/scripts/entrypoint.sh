#!/bin/sh -x

USER_UID=$(stat -c %u /code/Gemfile)
USER_GID=$(stat -c %g /code/Gemfile)

export USER_UID
export USER_GID

usermod -u "$USER_UID" decidim 2>/dev/null
groupmod -g "$USER_GID" decidim 2>/dev/null
usermod -g "$USER_GID" decidim 2>/dev/null

chown -R -h "$USER_UID" "$BUNDLE_PATH"
chgrp -R -h "$USER_GID" "$BUNDLE_PATH"

# Check all the gems are installed or fails.
bundle check
if [ $? -ne 0 ]; then
  echo "❌ Gems in Gemfile are not installed. Installing them with \"bundle install\"..."
  bundle install
else
  echo "✅ Gems in Gemfile are installed"
fi

# Check to see if there are migrations to install
bundle exec rake railties:install:migrations

# Check no migrations are pending migrations
if [ -z "$SKIP_MIGRATIONS" ]; then
  bundle exec rails db:migrate
else
  echo "⚠️ Skipping migrations"
fi

echo "✅ Migrations are all up"

echo "🚀 $@"
exec "$@"
