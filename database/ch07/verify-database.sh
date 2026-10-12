#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${NORTHSTAR_APP_URL:?Set NORTHSTAR_APP_URL without embedding a password.}"

identity="$(psql -X "$NORTHSTAR_APP_URL" -At --set ON_ERROR_STOP=1 \
  --command 'SELECT current_user || chr(124) || current_database();')"
if [[ "$identity" != 'northstar_app|northstar_market' ]]; then
  printf 'Refusing checks: connect as northstar_app to northstar_market.\n' >&2
  exit 2
fi
psql -X "$NORTHSTAR_APP_URL" --set ON_ERROR_STOP=1 \
  --file database/ch07/verify-allowed-operations.sql

expect_rejection() {
  local label="$1" state="$2" statement="$3" output
  if output="$(psql -X "$NORTHSTAR_APP_URL" --set ON_ERROR_STOP=1 \
    --set VERBOSITY=verbose \
    --command "BEGIN; $statement; ROLLBACK;" 2>&1)"; then
    printf 'FAILED: PostgreSQL accepted %s.\n' "$label" >&2
    exit 1
  fi
  if [[ "$output" != *"ERROR:  $state:"* ]]; then
    printf 'FAILED: %s did not produce SQLSTATE %s. Check connection and schema.\n' "$label" "$state" >&2
    exit 1
  fi
  printf 'Verified rejection: %s (SQLSTATE %s)\n' "$label" "$state"
}

expect_rejection 'runtime schema creation' 42501 \
  'CREATE TABLE northstar.runtime_must_not_create (id integer)'
expect_rejection 'runtime table removal' 42501 'DROP TABLE northstar.product'
expect_rejection 'runtime owner assumption' 42501 'SET ROLE northstar_owner'
expect_rejection 'missing name' 23502 'INSERT INTO northstar.product (price) VALUES (1.00)'
expect_rejection 'price below minimum' 23514 "INSERT INTO northstar.product (name, price) VALUES ('Invalid', 0.00)"
expect_rejection 'fractional cent' 23514 "INSERT INTO northstar.product (name, price) VALUES ('Invalid', 1.001)"
expect_rejection 'spaces-only name' 23514 "INSERT INTO northstar.product (name, price) VALUES ('   ', 1.00)"
expect_rejection 'oversized name' 22001 "INSERT INTO northstar.product (name, price) VALUES (repeat('n', 121), 1.00)"
expect_rejection 'NaN price' 23514 "INSERT INTO northstar.product (name, price) VALUES ('Invalid', 'NaN')"
expect_rejection 'infinite price' 23514 "INSERT INTO northstar.product (name, price) VALUES ('Invalid', 'Infinity')"
expect_rejection 'negative infinite price' 23514 "INSERT INTO northstar.product (name, price) VALUES ('Invalid', '-Infinity')"
printf 'Chapter 7 PostgreSQL privilege and constraint verification passed.\n'
