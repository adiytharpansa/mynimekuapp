#!/usr/bin/env bash
# Serve the Flutter web build as static output on PORT (default 3000).
# Writes deployment-output.json for the controller and stays in foreground.
set -euo pipefail
# NOTE: `cd` is a shell builtin that /usr/bin/time cannot execute; keep it
# untimed (same convention as the runtime launcher) and time every other step.
cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)"
/usr/bin/time -p printf 'project root: %s\n' "$PROJECT_ROOT"
PORT="${PORT:-3000}"
APP_DIR="$PROJECT_ROOT/nimeku_app"
SOURCE_BUILD="$APP_DIR/build/web"
STATIC_DIR="$PROJECT_ROOT/dist"
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
export PATH="$HOME/flutter/bin:$PATH"
/usr/bin/time -p which flutter
/usr/bin/time -p which python3
/usr/bin/time -p flutter --version
/usr/bin/time -p bash -c "cd '$APP_DIR' && flutter pub get"
/usr/bin/time -p test -f "$APP_DIR/lib/main.dart"
if /usr/bin/time -p test ! -f "$SOURCE_BUILD/index.html"; then
  /usr/bin/time -p bash -c "cd '$APP_DIR' && flutter build web"
elif /usr/bin/time -p test "$APP_DIR/lib/main.dart" -nt "$SOURCE_BUILD/index.html"; then
  /usr/bin/time -p bash -c "cd '$APP_DIR' && flutter build web"
fi
/usr/bin/time -p test -f "$SOURCE_BUILD/index.html"
/usr/bin/time -p mkdir -p "$STATIC_DIR"
/usr/bin/time -p rsync -a --delete "$SOURCE_BUILD/" "$STATIC_DIR/"
/usr/bin/time -p test -f "$STATIC_DIR/index.html"
/usr/bin/time -p mkdir -p "$WEB_DIR"
/usr/bin/time -p python3 -c "import json,os; p=os.path.abspath('.'); d=os.path.join(p,'dist'); w=os.environ.get('OPENCODE_WEB_DIR','/home/runner/work/_temp/omgithub-web'); os.makedirs(w,exist_ok=True); open(os.path.join(w,'deployment-output.json'),'w').write(json.dumps({'project':p,'directory':d}))"
/usr/bin/time -p cat "$WEB_DIR/deployment-output.json"
/usr/bin/time -p python3 -m http.server "$PORT" --directory "$STATIC_DIR"
