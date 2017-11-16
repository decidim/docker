FROM ruby:2.4.2
MAINTAINER info@codegram.com
ARG decidim_version

WORKDIR /app

RUN apt-get install -y git imagemagick wget

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && apt-get install -y nodejs=8.9.1-1nodesource1

RUN npm install -g yarn@v1.3.2

RUN gem install decidim:$decidim_version

ENTRYPOINT ["decidim"]
