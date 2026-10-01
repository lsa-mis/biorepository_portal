#!/usr/bin/env bash
# Runs the Axcess accessibility report on this machine, using your local
# master key (config/master.key or RAILS_MASTER_KEY) when present. This is the
# only supported way to scan with decrypted credentials; the GitHub workflow
# (.github/workflows/axcess-a11y.yml) never receives the key.
#
# Usage: AXCESS_DIR=/path/to/axcess script/ci/axcess_local.sh
#
# Requires: a local Postgres reachable by the test database config, and a
# checkout of lsa-mis/axcess set up once with `make setup && make migrate`.
# Keep the crawl flags in sync with the "Run Axcess scan" workflow step.
# Unlike CI, Click-Through is not limited to one click per page, because this
# script does not modify your Axcess checkout.
set -euo pipefail

: "${AXCESS_DIR:?Set AXCESS_DIR to your lsa-mis/axcess checkout}"
APP_PORT="${APP_PORT:-3000}"
APP_URL="http://127.0.0.1:${APP_PORT}"
AXCESS_MAX_PAGES="${AXCESS_MAX_PAGES:-5000}"

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT_DIR="${REPORT_DIR:-$repo_root/reports/axcess}"
AXCESS_DIR="$(cd "$AXCESS_DIR" && pwd)"
cd "$repo_root"

if curl -fsS "$APP_URL/up" > /dev/null 2>&1; then
  echo "Something is already serving $APP_URL; stop it or set APP_PORT." >&2
  exit 1
fi

if [ -n "${RAILS_MASTER_KEY:-}" ] || [ -f config/master.key ]; then
  echo "Using local master key"
else
  echo "No local master key; running with empty credentials (public pages only)"
fi

export RAILS_ENV=test
mkdir -p "$REPORT_DIR" log

bin/rails db:prepare
bin/rails db:seed
bin/rails runner script/ci/a11y_sample_data.rb
bin/rails assets:precompile

bin/rails server --environment test --port "$APP_PORT" --binding 127.0.0.1 > log/axcess-local-server.log 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2> /dev/null || true' EXIT

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

(
  cd "$AXCESS_DIR"
  git log -1 --format='Axcess %h %s (%cd)'
  uv run audit crawl "$APP_URL/" \
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
    uv run audit export --format "$fmt" --output "$REPORT_DIR/axcess.$ext"
  done
)

ruby script/ci/axcess_report.rb "$REPORT_DIR/axcess.json"
echo "Reports written to $REPORT_DIR"
