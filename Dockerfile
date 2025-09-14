FROM ruby:3.3.4

# Define build-time arguments
ARG RAILS_ENV
ARG RAILS_PORT

# Set environment variables using the build-time arguments
ENV RAILS_ENV=$RAILS_ENV
ENV RAILS_PORT=$RAILS_PORT
# Define a build-time argument for Bundler version (optional default value)
ARG BUNDLER_VERSION

RUN apt-get update && apt-get upgrade -y && apt-get install -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y nodejs yarn \
    build-essential \
    postgresql-client \
    p7zip \
    libpq-dev && \
    apt-get clean

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /app
# Copy package dependencies files only to ensure maximum cache hit
COPY ./Gemfile /app/Gemfile
COPY ./Gemfile.lock /app/Gemfile.lock

# Dynamically extract the Bundler version from Gemfile.lock if not provided
RUN if [ -z "$BUNDLER_VERSION" ]; then \
      BUNDLER_VERSION=$(grep -A 1 'BUNDLED WITH' Gemfile.lock | tail -n 1 | xargs); \
    fi && \
    echo "Installing Bundler version $BUNDLER_VERSION" && \
    gem install bundler:$BUNDLER_VERSION

RUN bundle install -j4 --retry 3 && \
# Remove unneeded gems
bundle clean --force && \
# Remove unneeded files from installed gems (cache, *.o, *.c)
rm -rf /usr/local/bundle/cache && \
find /usr/local/bundle/ -name "*.c" -delete && \
find /usr/local/bundle/ -name "*.o" -delete && \
find /usr/local/bundle/ -name ".git" -exec rm -rf {} + && \
find /usr/local/bundle/ -name ".github" -exec rm -rf {} + && \
# Remove additional unneeded decidim files
find /usr/local/bundle/ -name "spec" -exec rm -rf {} + && \
find /usr/local/bundle/ -wholename "*/decidim-dev/lib/decidim/dev/assets/*" -exec rm -rf {} +


COPY ./package-lock.json /app/package-lock.json
COPY ./package.json /app/package.json

# RUN npm ci

# copy the rest of files
COPY ./app /app/app
COPY ./bin /app/bin
COPY ./config /app/config
COPY ./db /app/db
COPY ./lib /app/lib
COPY ./public/*.* /app/public/
COPY ./config.ru /app/config.ru
COPY ./Rakefile /app/Rakefile
COPY ./postcss.config.js /app/postcss.config.js

# Compile assets with Webpacker or Sprockets
#
# Notes:
#   1. Executing "assets:precompile" runs "webpacker:compile", too

# RUN DB_ADAPTER=nulldb \
# SECRET_KEY_BASE=dummy \
# bin/rails assets:precompile

#RUN rm -rf node_modules tmp/cache vendor/bundle test spec app/packs .git*
RUN rm -rf tmp/cache vendor/bundle test spec .git*

COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]