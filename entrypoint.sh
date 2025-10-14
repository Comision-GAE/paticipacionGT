#!/bin/bash
set -euo pipefail

: "${RAILS_ENV}"
: "${RAILS_PORT:=3000}"
: "${RUN_MIGRATIONS:=false}"
: "${RUN_UPGRADE_TASKS:=false}"
: "${PRECOMPILE_ASSETS_AT_RUNTIME:=false}"
: "${DB_WAIT:=true}"
: "${DB_WAIT_TIMEOUT:=90}"
: "${DATABASE_HOST:=pg}"
: "${DATABASE_URL}"
: "${SECRET_KEY_BASE}"
DATABASE_PORT=5432

log()  { echo "[entrypoint] $*"; }
run()  { log ">> $*"; "$@"; }
log "Running environment RAILS_ENV: $RAILS_ENV"
log "Using DATABASE_URL: $DATABASE_URL"
log "Using SECRET_KEY_BASE: $SECRET_KEY_BASE"
[ -f tmp/pids/server.pid ] && rm -f tmp/pids/server.pid

wait_for_db() {
  [ "$DB_WAIT" = "true" ] || return 0
  start_ts=$(date +%s)
  while :; do
    ruby -e "require 'socket'; TCPSocket.new('${DATABASE_HOST}',${DATABASE_PORT}).close"       && { log "DB ready"; break; } || true
    elapsed=$(( $(date +%s) - start_ts ))
    [ "$elapsed" -ge "$DB_WAIT_TIMEOUT" ] && { log "DB timeout"; exit 1; }
    sleep 2
  done
}
wait_for_db

if [ "$RAILS_ENV" = "production" ]; then
  [ "$RUN_UPGRADE_TASKS" = "true" ] && run bundle exec rails decidim:upgrade
  [ "$RUN_MIGRATIONS" = "true" ] && run bundle exec rails db:migrate
  if [ "$PRECOMPILE_ASSETS_AT_RUNTIME" = "true" ]; then
    : "${SECRET_KEY_BASE:=dummy}"
    run bundle exec rails assets:clobber
    run bundle exec rails assets:precompile
  fi
  exec bundle exec puma -C config/puma.rb -e production -b "tcp://0.0.0.0:${RAILS_PORT}"
else
  run bundle exec rails db:prepare
  run bundle exec rails decidim:procfile:install
  exec bin/dev
fi