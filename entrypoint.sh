#!/bin/bash
set -e

# Source the .env file to load environment variables
if [ -f .env ]; then
  echo "Loading environment variables from .env file..."
  export $(grep -v '^#' .env | xargs)
fi

# Execute a command and log it
log_and_run() {
  echo "Running: $*"
  "$@"
}
# Wait for the database to be ready
wait_for_database() {
  echo "Waiting for database to be ready..."
  until pg_isready -h "$DATABASE_HOST" -p "$DATABASE_PORT" -U "$DATABASE_USERNAME"; do
    echo "Database is not ready. Retrying in 2 seconds..."
    sleep 2
  done
  echo "Database is ready!"
}

# Call the wait_for_database function before proceeding
wait_for_database

if [ "$RAILS_ENV" = "production" ]; then
  echo "=== Starting in PRODUCTION mode ==="

  # Clean pid if exists
  if [ -f tmp/pids/server.pid ]; then
    echo "Remove old PID file"
    rm tmp/pids/server.pid
  fi
  npm cache clean --force
  # Install/update JavaScript dependencies
  if [ -f "package.json" ]; then
    echo "Install/update JavaScript dependencies."
    npm install
  fi

  # Run decidim upgrade tasks
  log_and_run bin/rails decidim:upgrade RAILS_ENV=production

  # database migrate
  log_and_run bin/rails db:migrate RAILS_ENV=production

  # Clean and recompile assets
  log_and_run bin/rails assets:clean RAILS_ENV=production
  log_and_run bin/rails assets:precompile RAILS_ENV=production

  # Run Puma
  echo "=== Starting Puma ==="
  exec bundle exec puma -C config/puma.rb -e production
else
  echo "===Starting in DEVELOPMENT mode ==="

  # clean pid file if exists
  if [ -f tmp/pids/server.pid ]; then
    echo "Remove old PID file..."
    rm tmp/pids/server.pid
  fi

  # Upgrade tasks
  log_and_run bin/rails decidim:upgrade

  # Check if DATABASE_RECREATE is set
  if [ "$DATABASE_RECREATE" = "true" ]; then
    echo "DATABASE_RECREATE is set. Running rails db:create..."
    log_and_run bin/rails db:create
  else
    echo "DATABASE_RECREATE is not set. Skipping rails db:create."
  fi

  # Migrate files
  log_and_run bin/rails db:migrate
  npm cache clean --force
  if [ -f "package.json" ]; then
    echo "Install/update JavaScript dependencies."
    npm install
  fi
  # Precompile assets
  log_and_run bin/rails assets:precompile

  # Start Rails server
  echo "=== Booting Rails server ==="
  exec bin/rails s -b 0.0.0.0
fi
exec "$@"