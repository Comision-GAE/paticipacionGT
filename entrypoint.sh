#!/bin/bash
set -e

# Check if the database exists
if ! rails db:exists; then
  echo "Database does not exist. Creating and migrating..."
  rails db:create
  rails db:migrate
else
  echo "Database already exists. Skipping creation."
fi

# Start the application
exec "$@"