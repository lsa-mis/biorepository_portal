#!/usr/bin/env bash
# Runs the Axcess accessibility report on this machine, using your local
# master key (config/master.key or RAILS_MASTER_KEY) when present. This is the
# only supported way to scan with decrypted credentials; the GitHub workflow
# (.github/workflows/axcess-a11y.yml) never receives the key.
#
# Usage, from the root of this repository:
#   AXCESS_DIR=~/axcess script/ci/axcess_local.sh
#
# AXCESS_DIR is your own clone of lsa-mis/axcess, a separate repository. Set it
# up once as described in reports/README.md ("Run the report locally"): clone
# it outside this repository, check out AXCESS_COMMIT, create the empty folder
# src/audit/web/frontend/dist, then run `make setup` inside the clone (it is
# Axcess's Makefile target; this repository has no Makefile). You also need uv,
# a local Postgres reachable by the test database config, and this app's Ruby
# and gems.
#
# Output: one line per step, a progress line every 30 seconds while Axcess
# scans, then the findings grouped into issues (script/ci/axcess_report.rb).
# Rails and Axcess output goes to log/axcess-local.log, and its last lines are
# shown if a step fails. AXCESS_VERBOSE=1 shows that output in the terminal too.
#
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
  echo "Using your local master key."
else
  echo "No local master key, so the app runs with empty credentials."
fi

# Keep Axcess's scan database, rendered pages and screenshots in a temporary
# directory that is deleted on exit, instead of in the Axcess checkout.
axcess_data="$(mktemp -d "${TMPDIR:-/tmp}/axcess-data.XXXXXX")"
server_pid=""
cleanup() {
  if [ -n "$server_pid" ]; then
    kill "$server_pid" 2> /dev/null || true
    # Reaping the server keeps bash from reporting "Terminated: 15" for it.
    wait "$server_pid" 2> /dev/null || true
  fi
  rm -rf "$axcess_data"
}
trap cleanup EXIT

export RAILS_ENV=test
mkdir -p log

# The terminal shows one line per step, progress during the scan, and the
# report at the end, as plain text a screen reader can follow. What the tools
# print goes to run_log instead: its end is shown if a step fails, and
# AXCESS_VERBOSE=1 streams it to the terminal too. Written for bash 3.2, the
# version macOS ships.
run_log="$repo_root/log/axcess-local.log"
server_log="$repo_root/log/axcess-local-server.log"
: > "$run_log"
echo "Tool output goes to ${run_log#"$repo_root"/}."

step() {
  echo
  echo "Step $1 of 5: $2"
}

# Prints a message and the end of a log, then stops the script.
fail_with_log() {
  echo "$1" >&2
  echo "Last 40 lines of ${2#"$repo_root"/}:" >&2
  tail -n 40 "$2" >&2
  exit "${3:-1}"
}

# Runs a command with its output in run_log; stops the script if it fails.
quietly() {
  local status=0
  if [ "${AXCESS_VERBOSE:-0}" = 1 ]; then
    "$@" 2>&1 | tee -a "$run_log" || status=$?
  else
    "$@" >> "$run_log" 2>&1 || status=$?
  fi
  [ "$status" -eq 0 ] || fail_with_log "Failed with exit status $status: $*" "$run_log" "$status"
}

# Run in the background during the scan: every 30 seconds, prints how many
# pages Axcess has stored so far. Lines are added, never rewritten, so a screen
# reader announces each one once. Stops on its own if the script has ended.
report_progress() {
  local last=$SECONDS pages
  while kill -0 "$$" 2> /dev/null; do
    sleep 1
    [ $((SECONDS - last)) -ge 30 ] || continue
    last=$SECONDS
    pages=$(sqlite3 "$AUDIT_DB_PATH" 'SELECT COUNT(*) FROM pages' 2> /dev/null || true)
    if [ -n "$pages" ]; then
      echo "  Still scanning: $pages pages so far."
    else
      echo "  Still scanning."
    fi
  done
}

step 1 "Preparing the test database: schema, seeds and sample data."
quietly bin/rails db:prepare
quietly bin/rails db:seed
quietly bin/rails runner script/ci/a11y_sample_data.rb

step 2 "Compiling assets."
quietly bin/rails assets:precompile

step 3 "Starting Rails at $APP_URL"
bin/rails server --environment test --port "$APP_PORT" --binding 127.0.0.1 > "$server_log" 2>&1 &
server_pid=$!
for _ in $(seq 1 90); do
  curl -fsS "$APP_URL/up" > /dev/null 2>&1 && break
  kill -0 "$server_pid" 2> /dev/null || fail_with_log "Rails stopped before it was ready." "$server_log"
  sleep 1
done
curl -fsS "$APP_URL/up" > /dev/null 2>&1 || fail_with_log "Rails was not ready after 90 seconds." "$server_log"
echo "  Rails is ready."

# Nothing after this point needs the master key.
unset RAILS_MASTER_KEY

(
  cd "$AXCESS_DIR"
  export AUDIT_DATA_DIR="$axcess_data"
  export AUDIT_DB_PATH="$axcess_data/audit.db"
  export AUDIT_BLOB_DIR="$axcess_data/blobs"
  export AUDIT_LOG_DIR="$axcess_data/logs"

  step 4 "Scanning with Axcess $(git log -1 --format='%h from %cd' --date=short). This takes a few minutes."
  # --frozen installs exactly what uv.lock pins and never re-resolves.
  quietly uv run --frozen yoyo apply --database "sqlite:///$AUDIT_DB_PATH" --batch src/audit/db/migrations
  progress_pid=""
  # Stops the progress lines. Returns the status it was called with, so a
  # failed scan still exits with the scan's status rather than the reporter's.
  stop_progress() {
    local status=$?
    if [ -n "$progress_pid" ]; then
      { kill "$progress_pid"; wait "$progress_pid"; } 2> /dev/null || true
      progress_pid=""
    fi
    return "$status"
  }
  if [ "${AXCESS_VERBOSE:-0}" != 1 ]; then
    report_progress &
    progress_pid=$!
    trap stop_progress EXIT
  fi
  quietly uv run --frozen audit crawl "$APP_URL/" \
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
  stop_progress

  step 5 "Writing reports to ${REPORT_DIR#"$repo_root"/}"
  for fmt in json markdown xlsx csv; do
    ext=$fmt; [ "$fmt" = markdown ] && ext=md
    quietly uv run --frozen audit export --format "$fmt" --output "$REPORT_DIR/axcess.$ext"
  done
)

# The grouped, plain-text report. It ends with a summary and the report paths.
ruby script/ci/axcess_report.rb "$REPORT_DIR/axcess.json"
