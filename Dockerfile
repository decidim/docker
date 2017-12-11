FROM ruby:2.4.2
MAINTAINER info@codegram.com

ARG decidim_version

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /code

RUN apt-get install -y git imagemagick wget

RUN curl -sL https://deb.nodesource.com/setup_9.x | bash - \
    && apt-get install -y nodejs

RUN npm install -g npm@5.6.0

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update && apt-get install yarn=1.3.2-1

RUN gem update --system
RUN gem install -u \
    decidim:$decidim_version \
    decidim-verifications:$decidim_version

ENTRYPOINT ["decidim"]
