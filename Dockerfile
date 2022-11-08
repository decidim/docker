# For versions pinning, use the ./version.sh script
ARG RUBY_VERSION=3.1.2
ARG NODE_VERSION=16.9.1
ARG DECIDIM_VERSION=0.27.0

# https://docs.docker.com/develop/develop-images/multistage-build/
# node: pre-build node at the given version (@see ARGS)
FROM node:${NODE_VERSION}-alpine as node
# Supervisord: pre-build supervisord for alpine
FROM ochinchina/supervisord:latest as supervisord

# FIXME: go to alpine 3.16
#   There is an issue on alpine 3.16 for building seven_zip_ruby
#   @see https://github.com/metanorma/packed-mn/issues/169
FROM ruby:${RUBY_VERSION}-alpine3.15 as generator

LABEL version=$DECIDIM_VERSION
LABEL ruby_version=$RUBY_VERSION
LABEL node_version=$NODE_VERSION

ARG NODE_VERSION
ARG DECIDIM_VERSION

ENV BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    HOME=/home/decidim/app \ 
    ROOT=/home/decidim/app \          
    RAILS_ENV=production \
    RACK_ENV=production \
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
RUN npm install -g yarn --force
RUN gem update --system \
  && gem install bundler --silent \
  # Install dependencies:
  # - build-base: To ensure certain gems can be compiled
  # - postgresql-dev postgresql-client: Communicate with postgres through the postgres gem
  # - ruby-dev: charlock_holmes deps
  # - ruby-nokogiri: Nokogiri native dependencies
  # - imagemagick: for image processing
  # - git: for gemfiles using git (bundle will use it)
  # - python3: compilation tools
  # - p7zip: seven_zip_ruby deps
  && apk --update --no-cache add \
      build-base \
      tzdata \
      postgresql-dev postgresql-client \
      ruby-charlock_holmes \
      ruby-nokogiri \
      imagemagick \
      icu-dev \
      cmake \
      git \
      python3 \
      p7zip \
  && rm -rf /var/cache/apk/*

WORKDIR /home/decidim

RUN git clone -b v$DECIDIM_VERSION https://github.com/decidim/decidim generator \
  && mkdir -p $HOME/bin \
  && ln -s /usr/lib/p7zip/7z.so $HOME/bin/7z \
  && cd generator \
  && bundle install
COPY ./bundle/$DECIDIM_VERSION/tmp/Gemfile.patc[h] ./generator/decidim-generators/tmp/Gemfile.patch

RUN mkdir -p ./generator/decidim-generators/tmp \
  && touch ./generator/decidim-generators/tmp/Gemfile.patch \
  && cat ./generator/decidim-generators/tmp/Gemfile.patch >> ./generator/decidim-generators/Gemfile \
  && cd ./generator/decidim-generators \
  && bundle config set --global path 'vendor' \
  && bundle install \
  && bundle exec ./exe/decidim $HOME

WORKDIR $HOME

# Add the overrides for docker
COPY ./bundle/$DECIDIM_VERSION .
RUN bundle config set without 'development test' \
  && bundle install \
  # Keep migrations just in case someone needs them 
  && tar cfz tmp/migrations.tar.gz db/migrate \
  # Clean cache and migration images
  && rm -f db/migrate/*.rb \
  && rm -rf ./.git \
  && rm -rf ./tmp/**/* 

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
LABEL org.opencontainers.image.title="Decidim $DECIDIM_VERSION on docker"
LABEL org.opencontainers.image.description="Decidim instance on Docker, usable in production"
LABEL org.opencontainers.image.base.name="ruby:$RUBY_VERSION-alpine3.15"
LABEL org.opencontainers.image.licenses="AGPL-3.0-or-later"

ENV BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    LANG=en_US.UTF-8\
    DECIDIM_VERSION=${DECIDIM_VERSION:-27} \
    NODE_VERSION=$NODE_VERSION \
    RAILS_ENV=production \
    RACK_ENV=production \
    HOME=/home/decidim/app \ 
    ROOT=/home/decidim/app \ 
    PATH=/home/decidim/app/bin:/usr/local/bin:$PATH \ 
    RAILS_ENV=production \
    RACK_ENV=production\
    SECRET_KEY_BASE=my-insecure-password \
    RAILS_MASTER_KEY=my-insecure-password \
    DATABASE_HOST="pg" \
    DATABASE_DATABASE="decidim" \
    # Be sure to use differents user/password
    # when doing migrations. Running instances
    # should not use root users!
    DATABASE_USERNAME="example" \
    DATABASE_PASSWORD="insecure-password" \
    PORT=3000 \
    RAILS_MAX_THREAD=5 \
    DATABASE_MAX_POOL_SIZE=5\
    RAILS_FORCE_SSL="enabled" \
    RAILS_SERVE_STATIC_FILES="false"\
    SECRET_KEY_BASE="insecure-salt" \
    RAILS_ASSET_HOST=""\
    TZ="Europe/Madrid" \
    RAILS_PID_FILE="tmp/pids/server.pid" \
    RAILS_SERVE_STATIC_FILES="disabled" \
    CACHE_HOST="redis" \
    CACHE_USERNAME="default" \
    # Make thus password strong
    # `ACL GENPASS` in a redis instance does the job.
    # Be sure it is at least 64 chars long.
    # @see https://redis.io/docs/manual/security/acl/#how-passwords-are-stored-internally
    CACHE_PASSWORD="insecure-password" \
    CACHE_PORT="6379" \
    CACHE_DB="0" \
    # If you run an intensive instance,
    # use two different redis for cache and jobs
    # @see https://github.com/mperham/sidekiq/wiki/Using-Redis#multiple-redis-instances
    JOB_HOST="redis" \
    JOB_USERNAME="default" \
    JOB_PASSWORD="insecure-password" \
    JOB_PORT="6379" \
    JOB_DB="1" \
    CABLE_HOST="redis" \
    CABLE_USERNAME="default" \
    CABLE_PASSWORD="insecure-password" \
    CABLE_PORT="6379" \
    CABLE_DB="2" \
    DECIDIM_DEFAULT_LOCALE="en"\
    DECIDIM_AVAILABLE_LOCALES="fr,en,es"\
    DECIDIM_CURRENCY_UNIT="EUR"\
    DECIDIM_LOG_LEVEL="warn" \
    SMTP_AUTHENTICATION="plain"\
    SMTP_USERNAME="my-participatory-platform@iredmail.org"\
    SMTP_PASSWORD="insecure-password" \
    SMTP_ADDRESS="iredmail" \
    SMTP_DOMAIN="smtp.iredmail.org" \
    SMTP_PORT="587" \
    SMTP_STARTTLS_AUTO="enabled" \
    SMTP_VERIFY_MODE="none" \
    # Toggles for supervisord template
    RUN_RAILS="1" \
    RUN_SIDEKIQ="1"

RUN gem update --system \
  && gem install bundler --silent \
  # Install dependencies:
  # - tzdata: To manage timezones
  # - postgresql-dev postgresql-client: Communicate with postgres through the postgres gem
  # - ruby-nokogiri: Nokogiri native dependencies
  # - imagemagick: for image processing
  # - git: for gemfiles using git 
  # - bash curl vim: Utilities for sysadmins
  # - p7zip: seven_zip_ruby deps
  # - ttf-freefont: for pdf exports
  && apk --update --no-cache add \
        tzdata \
        postgresql-dev postgresql-client \
        ruby-nokogiri \
        ruby-charlock_holmes \
        imagemagick \
        git \
        bash curl vim\
        p7zip \
        ttf-freefont \
  && rm -rf /var/cache/apk/* \
  # Prepare workspace users
  && addgroup -S decidim \
  && adduser -S decidim -G decidim\
  # Link logs to common alpine log directory
  && mkdir -p $HOME/log \
  && mkdir -p /var/log/decidim \
  && ln -s $HOME/log /var/log/decidim 

# Install node at the required version
COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

# Add binaries
COPY ./bundle/docker/start /usr/local/bin/start
COPY ./bundle/docker/wait-for-it /usr/local/bin/wait-for-it
COPY ./bundle/docker/entrypoint /usr/local/bin/entrypoint
# Setup supervisord templates, will be populate in entrypoint
COPY ./bundle/docker/supervisord.template $HOME/config/supervisord.template

USER decidim
WORKDIR $HOME
# Setup volumes before copying, to avoid data-loss on binding
VOLUME $HOME/public
VOLUME $HOME/config
VOLUME $HOME/app
VOLUME $HOME/log

COPY --from=generator --chown=decidim:decidim $HOME $HOME
COPY ./bundle/docker/motd /etc/motd.template

  # Be sure gem is installed
RUN bundle config set without 'development test' \
  && bundle config set path 'vendor' \
  && (bundle check || bundle install) \
  # Prepare binaries
  && bundle binstubs wkhtmltopdf-binary \
  && bundle binstubs bundler --force \
  # Precompile to start faster
  && bundle exec bootsnap precompile --gemfile app/ lib/

# Define bash as the default shell
SHELL ["/bin/bash", "-c"]
# Ready to go!
EXPOSE 3000
ENTRYPOINT ["entrypoint"]
CMD ["start"]