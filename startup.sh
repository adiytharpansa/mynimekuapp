#!/usr/bin/env bash
# Once-per-worker prerequisites (executed once from the project directory).
set -euo pipefail
if /usr/bin/time -p test ! -x "$HOME/flutter/bin/flutter"; then
  /usr/bin/time -p git clone --depth 1 https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
fi
/usr/bin/time -p "$HOME/flutter/bin/flutter" --version
