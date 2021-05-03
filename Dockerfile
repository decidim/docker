ARG base_image=ghcr.io/decidim/decidim-generator:latest

FROM $base_image
LABEL maintainer="info@coditramuntana.com"

RUN decidim .
RUN bundle check || bundle install
RUN bundle exec rake assets:precompile

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true

EXPOSE 3000

ENTRYPOINT []

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
