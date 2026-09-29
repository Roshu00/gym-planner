#!/usr/bin/env bash
# Applies the migrations and seed to a fresh local Postgres with a stub auth
# schema, then runs the RLS tests. Needs psql and a server:
#   PGHOST=/var/tmp/pgc PGPORT=54329 PGUSER=postgres tool/test_db.sh
set -euo pipefail
cd "$(dirname "$0")/.."
db=chalkline_test_$$
psql -q -v ON_ERROR_STOP=1 -d postgres -c "create database $db"
trap 'psql -q -d postgres -c "drop database if exists $db" >/dev/null' EXIT
run() { psql -q -v ON_ERROR_STOP=1 -d "$db" "$@"; }
run -f supabase/tests/auth_stub.sql
for m in supabase/migrations/*.sql; do run -f "$m"; done
run -f supabase/seed.sql
run -f supabase/seed.sql # the seed is idempotent
run -f supabase/tests/rls_test.sql 2>&1 | grep -E 'ok:|FAILED|PASSED|ERROR'
