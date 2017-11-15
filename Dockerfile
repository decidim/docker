FROM ruby:2.4.2-alpine
MAINTAINER info@codegram.com

WORKDIR /app

ARG decidim_version
ENV DECIDIM_VERSION $decidim_version

RUN apk add --update nodejs
RUN apk add --update git

RUN apk add --update ruby-dev build-base \
    libxml2-dev libxslt-dev pcre-dev libffi-dev \
    postgresql-dev

RUN apk add --update imagemagick
RUN apk add --update tzdata

RUN gem install decidim:$DECIDIM_VERSION
ENTRYPOINT ["decidim"]
