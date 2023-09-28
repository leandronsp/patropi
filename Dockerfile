FROM ruby:3.2
ENV RUBY_YJIT_ENABLE=1
WORKDIR /app
RUN gem install oj
COPY patropi.rb .
COPY bin bin
COPY lib lib
CMD ["bin/rinha", "/var/rinha/source.rinha.json"]
