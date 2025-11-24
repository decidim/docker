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
  echo "❌ Gems in Gemfile are not installed, aborting..."
  bundle install
else
  echo "✅ Gems in Gemfile are installed"
fi

echo "🚀 $@"
exec "$@"
