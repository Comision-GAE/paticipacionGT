# ===== Stage 1: builder =====
FROM ruby:3.3.4 AS builder

ARG RAILS_ENV=production
ARG BUNDLER_VERSION
ENV RAILS_ENV=${RAILS_ENV} \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=true

# Dependencias de build + Node 20
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg build-essential libpq-dev postgresql-client tzdata; \
  mkdir -p /etc/apt/keyrings; \
  curl -fsSL https://deb.nodesource.com/setup_18.x  | bash - && \   
  apt-get update; \
  apt-get install -y --no-install-recommends nodejs; \
  rm -rf /var/lib/apt/lists/* \
  apt-get clean

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN set -eux; \
  if [ -z "${BUNDLER_VERSION:-}" ]; then \
    BUNDLER_VERSION="$(awk '/BUNDLED WITH/{getline; gsub(/^ +/,""); print; exit}' Gemfile.lock)"; \
  fi; \
  gem install -N bundler:"$BUNDLER_VERSION"; \
  bundle config set without 'development test'; \
  bundle config set path '/usr/local/bundle/'; \
  bundle install --jobs $(nproc) --retry 3 && \
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
RUN if [ -f package-lock.json ]; then npm ci; fi
RUN npm install --global yarn

# copy the rest of files
COPY ./app /app/app
COPY ./bin /app/bin
COPY ./config /app/config
COPY ./db /app/db
COPY ./lib /app/lib
COPY ./public/*.* /app/public/
COPY ./tmp /app/tmp
COPY ./config.ru /app/config.ru
COPY ./Rakefile /app/Rakefile
COPY ./postcss.config.js /app/postcss.config.js

RUN RAILS_ENV=production \
    SECRET_KEY_BASE=dummy \
    RAILS_MASTER_KEY=0b809804a9de874fb0627b6cf5b6cada \
    DB_ADAPTER=nulldb \
    bin/rails assets:precompile

# Remove unneeded files
RUN rm -rf node_modules tmp/cache vendor/bundle test spec app/packs .git

# ===== Stage 2: runtime =====
FROM ruby:3.3.4-slim AS runtime

ARG RAILS_ENV=production
ARG RAILS_PORT=3000
ENV RAILS_ENV=${RAILS_ENV} \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_PORT=${RAILS_PORT}

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends ca-certificates curl tzdata libpq5 imagemagick; \
  rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 app && useradd -m -u 1000 -g 1000 app 

WORKDIR /app
COPY ./entrypoint.sh /app/entrypoint.sh
COPY --from=builder --chown=app:app  /usr/local/bundle/ /usr/local/bundle
COPY --from=builder --chown=app:app /app /app
RUN chown -R app:app /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

USER app
EXPOSE ${RAILS_PORT}

ENTRYPOINT ["/app/entrypoint.sh"]