FROM ruby:2.5.0
LABEL maintainer="info@codegram.com"

ARG decidim_version

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /code

RUN apt-get install -y git imagemagick wget

RUN curl -sL https://deb.nodesource.com/setup_9.x | bash - \
  && apt-get install -y nodejs

RUN npm install -g npm

RUN gem update --system
RUN gem install decidim:$decidim_version

ENTRYPOINT ["decidim"]
