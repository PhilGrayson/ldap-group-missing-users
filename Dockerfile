FROM ruby:alpine

COPY Gemfile .
RUN bundle install
RUN bundle clean --force

RUN apk --no-cache del alpine-sdk
RUN rm -rf /usr/local/bundle/cache/*
RUN rm -rf /root/.bundle

COPY missing-users.rb missing-users.rb
ENTRYPOINT ["ruby", "/missing-users.rb"]
