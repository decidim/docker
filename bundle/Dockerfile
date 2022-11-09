# For versions pinning, use the ./version.sh script
ARG RUBY_VERSION=3.0
ARG NODE_VERSION=16.9.1
ARG DECIDIM_VERSION=0.27.0

# https://docs.docker.com/develop/develop-images/multistage-build/
# node: pre-build node at the given version (@see ARGS)
FROM node:${NODE_VERSION}-alpine as node

# There is an issue on alpine 3.16 for building seven_zip_ruby
# @see https://github.com/metanorma/packed-mn/issues/169
FROM ruby:${RUBY_VERSION}-alpine3.15 as generator

LABEL version=$DECIDIM_VERSION
LABEL ruby_version=$RUBY_VERSION
LABEL node_version=$NODE_VERSION

ARG NODE_VERSION
ARG DECIDIM_VERSION

ENV BUNDLE_JOBS=8 \
    BUNDLE_RETRY=3 \
    HOME=/home/decidim/app \ 
    ROOT=/home/decidim/app \          
    BUNDLE_APP_CONFIG=/home/decidim/app/.bundle \
    RAILS_ENV=production \
    RACK_ENV=production \
    NODE_ENV=development \
    LANG=en_US.UTF-8\
    PATH=/home/decidim/app/bin:/usr/local/bin:$PATH \
    # Pass ARGS to ENV
    DECIDIM_VERSION=$DECIDIM_VERSION \
    NODE_VERSION=$NODE_VERSION 

# Add node binaries for precompilation (used by the generator)
COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

RUN npm install -g --force yarn webpack  \
  && gem update --system \
  && apk update \
  && apk upgrade \
  # Install dependencies:
  && apk --update --no-cache add \
      # help with native gem compilation
      build-base ruby-dev alpine-sdk python3 \
      icu-dev cmake libc-dev linux-headers libxml2-dev libxslt-dev readline-dev gcc \
      # timezone management
      tzdata \
      # postgres connection
      postgresql-dev postgresql-client \
      # deps for gem charlock_holmes and nokogiri, to use system libraries
      ruby-charlock_holmes \
      ruby-nokogiri \
      # image processing
      imagemagick \
      # gem using git
      git \
  && rm -rf /var/cache/apk/* 

WORKDIR /home/decidim

# Run the generator
RUN bundle config set --global without 'development:test' \
  && bundle config set --global path 'vendor' \
  && gem install decidim -v $DECIDIM_VERSION \
  && decidim $HOME 

# Go in the generated decidim application. 
WORKDIR $HOME
# Prepare the decidim application, with correct ruby version, 
# and binaries
# Add all the overrides, for default configuration purpose.
COPY ./$DECIDIM_VERSION/ .

# Set the ruby version from the current version used.
# Useful if you eject your container and want to work without docker.
RUN echo $RUBY_VERSION > .ruby-version \
  && bundle install \
  # It can be useful to have a backup of your migrations.
  && tar cfz tmp/migrations.bak.tar.gz db/migrate \
  && rm -f ./config/credentials.yml.enc \
  && rm -rf ./.git docker-compose-etherpad.yml docker-compose.yml Dockerfile \
  && rm -rf node_modules tmp/* spec test \
  && yarn cache clean \
  && truncate -s 0 /var/log/*log \
  && vendor_path=$(bundle show rails | sed 's/\/gems\/.*//') && rm -rf $vendor_path/cache $vendor_path/build_info $vendor_path/doc

# Setup 7z.so seven_zip dep:
RUN mkdir -p $HOME/lib/seven_zip_ruby \
  && ln -s /usr/lib/p7zip/7z.so $HOME/lib/seven_zip_ruby/7z.so
  
# Precompile assets, as we have node, yarn and webpack.
RUN npm ci \
  && SECRET_KEY_BASE="assets" bundle exec rails assets:precompile \
  && rm -rf node_modules

########################################################################################
# Final image
# Get files from previous image, and prepare everything to run the 
# docker image.
########################################################################################
FROM ruby:${RUBY_VERSION}-alpine3.15
ARG NODE_VERSION
ARG DECIDIM_VERSION
LABEL org.opencontainers.image.authors="hola@decidim.org"
LABEL org.opencontainers.image.vendor="Decidim"
LABEL org.opencontainers.image.title="Decidim $DECIDIM_VERSION on docker. (node=$NODE_VERSION,ruby=$RUBY_VERSION)"
LABEL org.opencontainers.image.description="Decidim instance on Docker, usable in production"
LABEL org.opencontainers.image.base.name="ruby:$RUBY_VERSION-alpine3.15"
LABEL org.opencontainers.image.licenses="AGPL-3.0-or-later"

# Rails configuration
ENV BUNDLE_JOBS=8 \
    BUNDLE_RETRY=3 \
    BUNDLE_APP_CONFIG=/home/decidim/app/.bundle \
    EDITOR=vi \
    LANG=en_US.UTF-8 \
    TZ="Europe/Madrid" \
    NODE_VERSION=$NODE_VERSION \
    RUBY_VERSION=$RUBY_VERSION \
    RAILS_ENV=production \
    RACK_ENV=production \
    NODE_ENV=production \
    HOME=/home/decidim/app \ 
    ROOT=/home/decidim/app \ 
    PATH=/home/decidim/app/bin:/usr/local/bin:$PATH \
    PORT=3000 \
    RAILS_FORCE_SSL="enabled" \
    RAILS_SERVE_STATIC_FILES="false"\
    RAILS_ASSET_HOST="" \
    RAILS_MAX_THREAD=5 \
    RAILS_PID_FILE="tmp/pids/server.pid" \
    RAILS_SERVE_STATIC_FILES="disabled" \
    RAILS_MASTER_KEY="my-insecure-password" \
    SECRET_KEY_BASE="insecure-salt"

# Supervisord configuration
ENV DECIDIM_RUN_RAILS="1" \
    DECIDIM_RUN_SIDEKIQ="1"

# Decidim configuration
ENV DECIDIM_VERSION=${DECIDIM_VERSION:-27} \
    DECIDIM_SEED="1"\
    DECIDIM_DEFAULT_LOCALE="en"\
    DECIDIM_AVAILABLE_LOCALES="fr,en,es"\
    DECIDIM_CURRENCY_UNIT="EUR"\
    DECIDIM_LOG_LEVEL="warn"

# Database configuration
ENV DATABASE_HOST="pg" \
    DATABASE_DATABASE="decidim" \
    # Be sure to use differents user/password
    # when doing migrations. Running instances
    # should not use root users!
    DATABASE_USERNAME="example" \
    DATABASE_PASSWORD="insecure-password" \
    DATABASE_MAX_POOL_SIZE=5

# Cache configuration
ENV CACHE_HOST="redis" \
    CACHE_USERNAME="default" \
    # Make thus password strong
    # `ACL GENPASS` in a redis instance does the job.
    # Be sure it is at least 64 chars long.
    # @see https://redis.io/docs/manual/security/acl/#how-passwords-are-stored-internally
    CACHE_PASSWORD="insecure-password" \
    CACHE_PORT="6379" \
    CACHE_DB="0"

# Job Configuration (Sidekiq)
# WARNING: If you run an intensive instance,
# use two different redis for cache and jobs
# @see https://github.com/mperham/sidekiq/wiki/Using-Redis#multiple-redis-instances
ENV JOB_HOST="redis" \
    JOB_USERNAME="default" \
    JOB_PASSWORD="insecure-password" \
    JOB_PORT="6379" \
    JOB_DB="1"

# SMTP configuration
ENV SMTP_AUTHENTICATION="plain" \
    SMTP_USERNAME="my-participatory-platform@iredmail.org" \
    SMTP_PASSWORD="insecure-password" \
    SMTP_ADDRESS="iredmail" \
    SMTP_DOMAIN="smtp.iredmail.org" \
    SMTP_PORT="587" \
    SMTP_STARTTLS_AUTO="enabled" \
    SMTP_VERIFY_MODE="none" 

RUN gem update --system \
  && apk update \
  && apk upgrade \
  && gem install bundler --silent \
  # Install dependencies:
  && apk --update --no-cache add \
        # nokogiri native deps (don't need full ruby-nokogiri, just these headers)
        libxslt-dev \
        # manage timezones
        tzdata \
        # communicate with postgres through the postgres gem
        postgresql-dev \
        # for image processing
        imagemagick \
        # allows gem to use git
        git \
        # sysadmins utilities
        curl \
        p7zip \ 
  && rm -rf /var/cache/apk/* \
  # Prepare workspace users
  && addgroup -S decidim \
  && adduser -S decidim -G decidim \
  && chown decidim:decidim /etc/motd \
  # Link logs to common alpine log directory
  && mkdir -p $HOME/log \
  && mkdir -p /var/log/decidim \
  && ln -s $HOME/log /var/log/decidim \
  && truncate -s 0 /var/log/*log

# Setup templates, will be used at runtime through entrypoint (see docker-entrypoint.d directory)
COPY ./docker/docker-entrypoint.d /docker-entrypoint.d
COPY ./docker/templates /usr/local/share/decidim/templates

# Setup volumes before copying, to avoid data-loss on binding
VOLUME $HOME/public
VOLUME $HOME/config
VOLUME $HOME/app
VOLUME $HOME/log

# Add binaries, to start the container
COPY docker/etc/ /etc/
COPY ./docker/bin /usr/local/bin/

USER decidim
COPY --from=generator --chown=decidim $HOME $HOME

WORKDIR $HOME
# Set the config again, the same as the previous image, 
# to to avoid rebuilding native extensions.
RUN bundle config set --global without 'development:test' \
  && bundle config set --global path 'vendor' \
  && bundle config --global build.nokogiri --use-system-libraries \
  && bundle config --global build.charlock_holmes --with-icu-dir=/usr/include
  
# Define the default shell
SHELL ["/bin/sh", "-c", "set -e;"]

# Expose the rails port
EXPOSE 3000

# Entrypoint will run all the /docker-entrypoint.d/*.sh scripts
ENTRYPOINT ["docker-entrypoint"]
CMD ["start"]  