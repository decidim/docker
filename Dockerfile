FROM ruby:2.4.2
MAINTAINER info@codegram.com

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get install -y git imagemagick wget

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs

WORKDIR /app
COPY Gemfile .
RUN bundle install --without=development,test

ENTRYPOINT ["bundle exec decidim"]
