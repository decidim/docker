FROM ruby:2.4.2
MAINTAINER info@codegram.com

ARG decidim_version
ENV DECIDIM_VERSION $decidim_version

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /app

RUN apt-get install -y nodejs git \
                       imagemagick wget

RUN gem install decidim:$DECIDIM_VERSION
ENTRYPOINT ["decidim"]
