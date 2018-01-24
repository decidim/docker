#!/bin/sh -x

# https://github.com/docker-library/ruby/issues/66
export BUNDLE_PATH=/gems
export BUNDLE_BIN=/gems/bin
export BUNDLE_APP_CONFIG=/gems/config

export USER_UID=`stat -c %u /code/Gemfile`
export USER_GID=`stat -c %g /code/Gemfile`

usermod -u $USER_UID decidim 2> /dev/null
groupmod -g $USER_GID decidim 2> /dev/null
usermod -g $USER_GID decidim 2> /dev/null

chown -R -h $USER_UID $BUNDLE_PATH 2> /dev/null
chgrp -R -h $USER_GID $BUNDLE_PATH 2> /dev/null

/usr/bin/sudo -EH -u decidim "$@"
