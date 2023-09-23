FROM ruby:3.2
ENV RUBY_YJIT_ENABLE=1
WORKDIR /app
COPY patropi.rb .
COPY lib lib
CMD ["ruby", "patropi.rb"]
