#!/bin/sh -x

# Check all the gems are installed or fails.
if ! bundle check; then
  echo "❌ Gems within the Gemfile are not installed. Installing them with \"bundle install\"..."
  if ! bundle install; then
    echo "❌ bundle install failed."
    exit 1
  fi
else
  echo "✅ Gems in Gemfile are installed!"
fi

echo "🚀" "$@"
exec "$@"
