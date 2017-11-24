FROM ruby:2.4.2
MAINTAINER info@codegram.com
ARG decidim_version

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /code

RUN apt-get install -y git imagemagick wget

RUN curl -sL https://deb.nodesource.com/setup_9.x | bash - \
    && apt-get install -y nodejs=9.2.0-1nodesource1

RUN npm install -g yarn@v1.3.2

RUN gem install decidim:$decidim_version

ENTRYPOINT ["decidim"]
