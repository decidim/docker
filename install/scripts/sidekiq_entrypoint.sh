#!/bin/sh -x

# Check all the gems are installed or fails.
if ! bundle check; then
  echo "❌ Gems in Gemfile are not installed. Installing them with \"bundle install\"..."
  bundle install
else
  echo "✅ Gems in Gemfile are installed"
fi

echo "🚀" "$@"
exec "$@"
