#!/usr/bin/env bash
# Runs the Axcess accessibility report on this machine, using your local
# master key (config/master.key or RAILS_MASTER_KEY) when present. This is the
# only supported way to scan with decrypted credentials; the GitHub workflow
# (.github/workflows/axcess-a11y.yml) never receives the key.
#
# Usage: AXCESS_DIR=/path/to/axcess script/ci/axcess_local.sh
#
# Requires: a local Postgres reachable by the test database config, and a
# checkout of lsa-mis/axcess at AXCESS_COMMIT, set up once with `make setup`.
# Keep the crawl flags in sync with the "Run Axcess scan" workflow step.
# Unlike CI, Click-Through is not limited to one click per page, because this
# script does not modify your Axcess checkout.
#
# Axcess runs as your user, so it could read config/master.key from disk.
# To limit that, the script only runs a reviewed Axcess commit with its locked
# dependencies, keeps RAILS_MASTER_KEY out of the Axcess environment, and
# deletes the scan data afterwards.
set -euo pipefail

# The reviewed Axcess commit. Review the Axcess changes before moving this.
AXCESS_COMMIT=6eefa502f35283a97af1ecbfbb2a3d62a0b21ece

: "${AXCESS_DIR:?Set AXCESS_DIR to your lsa-mis/axcess checkout}"
APP_PORT="${APP_PORT:-3000}"
APP_URL="http://127.0.0.1:${APP_PORT}"
AXCESS_MAX_PAGES="${AXCESS_MAX_PAGES:-5000}"

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT_DIR="${REPORT_DIR:-$repo_root/reports/axcess}"
AXCESS_DIR="$(cd "$AXCESS_DIR" && pwd)"
cd "$repo_root"
mkdir -p "$REPORT_DIR"
REPORT_DIR="$(cd "$REPORT_DIR" && pwd)"

# DATABASE_URL overrides config/database.yml even with RAILS_ENV=test, and the
# steps below load the schema and seed data. Only allow a local *_test database.
# The URL is never printed, because it may contain a password.
if [ -n "${DATABASE_URL:-}" ]; then
  local_test_db='^postgres(ql)?://([^/@]*@)?(localhost|127\.0\.0\.1|\[::1\])(:[0-9]+)?/[A-Za-z0-9_]+_test(\?.*)?$'
  if ! [[ "$DATABASE_URL" =~ $local_test_db ]]; then
    echo "DATABASE_URL is set but is not a local *_test database; unset it or point it at one." >&2
    exit 1
  fi
fi

axcess_head="$(git -C "$AXCESS_DIR" rev-parse HEAD)"
if [ "$axcess_head" != "$AXCESS_COMMIT" ]; then
  echo "Axcess checkout is at $axcess_head, not the reviewed commit $AXCESS_COMMIT." >&2
  echo "Run: git -C \"$AXCESS_DIR\" fetch origin && git -C \"$AXCESS_DIR\" checkout $AXCESS_COMMIT" >&2
  exit 1
fi
if ! git -C "$AXCESS_DIR" diff --quiet HEAD --; then
  echo "Axcess checkout has uncommitted changes to tracked files; stash or discard them first." >&2
  exit 1
fi

if curl -fsS "$APP_URL/up" > /dev/null 2>&1; then
  echo "Something is already serving $APP_URL; stop it or set APP_PORT." >&2
  exit 1
fi

if [ -n "${RAILS_MASTER_KEY:-}" ] || [ -f config/master.key ]; then
  echo "Using local master key"
else
  echo "No local master key; running with empty credentials (public pages only)"
fi

# Keep Axcess's scan database, rendered pages and screenshots in a temporary
# directory that is deleted on exit, instead of in the Axcess checkout.
axcess_data="$(mktemp -d "${TMPDIR:-/tmp}/axcess-data.XXXXXX")"
server_pid=""
cleanup() {
  if [ -n "$server_pid" ]; then
    kill "$server_pid" 2> /dev/null || true
  fi
  rm -rf "$axcess_data"
}
trap cleanup EXIT

export RAILS_ENV=test
mkdir -p log

bin/rails db:prepare
bin/rails db:seed
bin/rails runner script/ci/a11y_sample_data.rb
bin/rails assets:precompile

bin/rails server --environment test --port "$APP_PORT" --binding 127.0.0.1 > log/axcess-local-server.log 2>&1 &
server_pid=$!

for _ in $(seq 1 90); do
  if curl -fsS "$APP_URL/up" > /dev/null 2>&1; then
    echo "Rails is up at $APP_URL"
    break
  fi
  if ! kill -0 "$server_pid" 2> /dev/null; then
    echo "Rails server exited; see log/axcess-local-server.log" >&2
    exit 1
  fi
  sleep 1
done
curl -fsS "$APP_URL/up" > /dev/null 2>&1 || { echo "Rails did not become ready within 90s" >&2; exit 1; }

# Nothing after this point needs the master key.
unset RAILS_MASTER_KEY

(
  cd "$AXCESS_DIR"
  export AUDIT_DATA_DIR="$axcess_data"
  export AUDIT_DB_PATH="$axcess_data/audit.db"
  export AUDIT_BLOB_DIR="$axcess_data/blobs"
  export AUDIT_LOG_DIR="$axcess_data/logs"
  git log -1 --format='Axcess %h %s (%cd)'
  # --frozen installs exactly what uv.lock pins and never re-resolves.
  uv run --frozen yoyo apply --database "sqlite:///$AUDIT_DB_PATH" --batch src/audit/db/migrations
  uv run --frozen audit crawl "$APP_URL/" \
    --max-pages "$AXCESS_MAX_PAGES" \
    --axe-level AA \
    --wcag-version 2.1 \
    --ignore-robots \
    --skip-ocr \
    --skip-vlm \
    --skip-synthesize \
    --skip-semantic \
    --block /export_to_csv \
    --block /users/auth \
    --block sign_out \
    --block 'q%5B' \
    --block 'return_to=%2Fitems%2Fsearch%3F'
  for fmt in json markdown xlsx csv; do
    ext=$fmt; [ "$fmt" = markdown ] && ext=md
    uv run --frozen audit export --format "$fmt" --output "$REPORT_DIR/axcess.$ext"
  done
)

ruby script/ci/axcess_report.rb "$REPORT_DIR/axcess.json"
echo "Reports written to $REPORT_DIR"
