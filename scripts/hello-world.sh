#!/bin/sh
set -e
 
bundle exec rake db:environment:set RAILS_ENV=development
bundle exec rake db:migrate:reset
bundle exec rake db:seed

exec "$@"
