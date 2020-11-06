FROM ruby:2.6.6
LABEL maintainer="info@coditramuntana.com"

ARG decidim_version

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /code

RUN apt-get install -y git imagemagick wget \
  && apt-get clean

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
  && apt-get install -y nodejs \
  && apt-get clean

RUN npm install -g npm@6.3.0

RUN gem install bundler \
  && gem install decidim-templates:$decidim_version \
  && gem install decidim:$decidim_version

ENTRYPOINT ["decidim"]
