#!/bin/sh -x

# Check all the gems are installed or fails.
bundle check
if [ $? -ne 0 ]; then
  echo "❌ Gems in Gemfile are not installed. Installing them with \"bundle install\"..."
  bundle install
else
  echo "✅ Gems in Gemfile are installed"
fi

echo "🚀 $@"
exec "$@"
