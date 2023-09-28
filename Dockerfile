FROM ruby:3.2
ENV RUBY_YJIT_ENABLE=1
WORKDIR /app
COPY patropi.rb .
COPY bin bin
COPY lib lib
RUN gem install oj
CMD ["bin/rinha", "/var/rinha/source.rinha.json"]
