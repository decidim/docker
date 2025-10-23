#!/bin/bash

set -xe

echo "───────────────────────────────────────────────"
echo "Now we are going to generate some Gemfiles so that we can track gem dependencies"
echo
echo "You will find everything in the Gemfile.wrapper and Gemfile.local"

cat >Gemfile.wrapper <<EOF
eval_gemfile "Gemfile"
eval_gemfile "Gemfile.local"
EOF

cat >Gemfile.local <<EOF
# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "sidekiq"
gem "sidekiq-cron"
EOF

if [ $EXTERNAL_STORAGE == "s3" ]; then
  echo "gem \"aws-sdk-s3\"" >>Gemfile.local
fi
