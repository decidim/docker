#!/bin/sh
set -e

# runs db:drop, db:create and db:migrate.
# We can't use db:schema:load because we don't have the db/schema.rb
# file when we create the app for the first time and migrations haven't
# been run yet.
bundle exec rake db:migrate:reset
# Adds basic system, admin and user accounts, and lorem ipsum content.
bundle exec rake db:seed

exec "$@"
