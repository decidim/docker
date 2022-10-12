# For versions pinning, use the ./version.sh script
ARG RUBY_VERSION=3.0.2
ARG NODE_VERSION=16.9.1
ARG DECIDIM_VERSION=0.27

# https://docs.docker.com/develop/develop-images/multistage-build/
FROM node:${NODE_VERSION}-alpine as node
FROM ochinchina/supervisord:latest as supervisord

FROM ruby:${RUBY_VERSION}-alpine as generator
ARG NODE_VERSION
ARG DECIDIM_VERSION

ENV BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    NODE_VERSION=$NODE_VERSION \
    HOME=/home/decidim/app \ 
    HOME_PATH=/home/decidim/app \ 
    RAILS_ENV=production \
    RACK_ENV=production \
    DECIDIM_VERSION=$DECIDIM_VERSION

# Add node for precompilation (used by the generator)
COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

RUN gem update --system \
  && gem install bundler --silent \
  # Install dependencies:
  # - build-base: To ensure certain gems can be compiled
  # - postgresql-dev postgresql-client: Communicate with postgres through the postgres gem
  # - ruby-dev: charlock_holmes deps
  # - ruby-nokogiri: Nokogiri native dependencies
  # - imagemagick: for image processing
  # - git: for gemfiles using git 
  # - bash curl: to download nvm and install it
  # - zlib-dev p7zip libstdc++ gcc: seven_zip_ruby deps
  && apk --update --no-cache add \
      build-base \
      tzdata \
      postgresql-dev postgresql-client \
      ruby-dev \
      ruby-nokogiri \
      imagemagick \
      ruby-charlock_holmes icu-dev \
      cmake \
      git \
      bash curl \
      python3 \
      zlib-dev p7zip libstdc++ \
  && rm -rf /var/cache/apk/*


WORKDIR /home/decidim

RUN git clone --branch release/$DECIDIM_VERSION-stable https://github.com/decidim/decidim generator
RUN cd generator \
  && bundle install

RUN cd generator/decidim-generators \
  && bundle install \
  && bundle config set without 'development test' \
  && bundle config set path 'vendor' \
  && bundle exec ./exe/decidim $HOME

WORKDIR $HOME

RUN rm -f db/migrate/*.rb \
  && rm -rf ./.git \
  && rm -rf ./tmp/**/* 

# Add the overrides
COPY ./overrides/$DECIDIM_VERSION .

# Compose final image
FROM ruby:${RUBY_VERSION}-alpine
ARG NODE_VERSION
ARG DECIDIM_VERSION
ENV BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    DECIDIM_VERSION=${DECIDIM_VERSION:-27} \
    NODE_VERSION=$NODE_VERSION \
    RAILS_ENV=production \
    RACK_ENV=production \
    HOME=/home/decidim/app \ 
    HOME_PATH=/home/decidim/app \ 
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
    PORT=3000\
    RAILS_MAX_THREAD=5\
    RAILS_FORCE_SSL="enabled" \
    RAILS_SERVE_STATIC_FILES="false"\
    SECRET_KEY_BASE="insecure-salt" \
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
    DECIDIM_DEFAULT_LOCALE="en"\
    DECIDIM_AVAILABLE_LOCALES="fr,en,es"\
    DECIDIM_CURRENCY_UNIT="EUR"\
    DECIDIM_LOG_LEVEL="warn" \
    SMTP_AUTHENTICATION="plain"\
    SMTP_USERNAME="my-participatory-plateform@iredmail.org"\
    SMTP_PASSWORD="my-insecure-password" \
    SMTP_ADDRESS="iredmail" \
    SMTP_DOMAIN="smtp.iredmail.org" \
    SMTP_PORT="587" \
    SMTP_STARTTLS_AUTO="enabled"\
    SMTP_VERIFY_MODE="none"\
    RUN_RAILS="1" \
    RUN_SIDEKIQ="1"

RUN gem update --system \
  && gem install bundler --silent \
  # Install dependencies:
  # - postgresql-dev postgresql-client: Communicate with postgres through the postgres gem
  # - ruby-nokogiri: Nokogiri native dependencies
  # - imagemagick: for image processing
  # - git: for gemfiles using git 
  # - bash curl
  # - ttf-freefont wkhtmltopdf: for pdf exports
  # - p7zip libstdc++ gcc: seven_zip_ruby deps
  && apk --update --no-cache add \
        tzdata \
        postgresql-dev postgresql-client \
        ruby-nokogiri \
        ruby-charlock_holmes \
        imagemagick \
        git \
        bash curl \
        ttf-freefont wkhtmltopdf \
  && rm -rf /var/cache/apk/*

# Install node at the required version
COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

# Add binaries
COPY ./docker/start /usr/local/bin/start
COPY ./docker/wait-for-it /usr/local/bin/wait-for-it
COPY ./docker/entrypoint /usr/local/bin/docker-entrypoint

# Setup supervisord templates, will be populate in entrypoint
COPY ./docker/supervisord.template /home/decidim/app/config/supervisord.template

# Prepare workspace
RUN addgroup -S decidim \
    && adduser -S decidim -G decidim

USER decidim
WORKDIR $HOME

# Setup volumes before copying, to avoid data-loss on binding
VOLUME $HOME/public
VOLUME $HOME/config
VOLUME $HOME/app
VOLUME $HOME/log

COPY --from=generator --chown=decidim:decidim $HOME $HOME

RUN bundle config set without 'development test' \
  && bundle config set path 'vendor' \
  && bundle check || bundle install 

# Define bash as the default shell
SHELL ["/bin/bash", "-c"]

# Ready to go!
EXPOSE 3000
ENTRYPOINT ["entrypoint"]
CMD ["start"]