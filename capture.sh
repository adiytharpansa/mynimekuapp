#!/usr/bin/env bash
# Capture desktop + mobile screenshots of the exact preview URL.
# Inputs: CAPTURE_URL, CAPTURE_DIR. Leaves the app running.
# Exit 75 = temporary navigation/browser infra failure, 1 = script/render defect.
set -euo pipefail
# NOTE: `cd` is a shell builtin that /usr/bin/time cannot execute; keep it
# untimed (same convention as the runtime launcher) and time every other step.
cd "$(dirname "$0")"
if /usr/bin/time -p test -z "${CAPTURE_URL:-}"; then
  echo 'Set CAPTURE_URL to the exact preview URL.' >&2
  exit 1
fi
if /usr/bin/time -p test -z "${CAPTURE_DIR:-}"; then
  echo 'Set CAPTURE_DIR to the evidence directory.' >&2
  exit 1
fi
if /usr/bin/time -p test -z "${RUNTIME_DIR:-}"; then
  echo 'Set RUNTIME_DIR to the runtime directory.' >&2
  exit 1
fi
export CAPTURE_READY_SELECTOR="${CAPTURE_READY_SELECTOR:-canvas}"
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p node "$RUNTIME_DIR/scripts/default-capture.mjs"
/usr/bin/time -p ls -la "$CAPTURE_DIR/final-desktop.png" "$CAPTURE_DIR/final-mobile.png"
/usr/bin/time -p test -s "$CAPTURE_DIR/final-desktop.png"
/usr/bin/time -p test -s "$CAPTURE_DIR/final-mobile.png"
