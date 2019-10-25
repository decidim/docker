FROM ruby:2.6.5
LABEL maintainer="info@codegram.com"

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

RUN gem install decidim:$decidim_version

ENTRYPOINT ["decidim"]
