#!/usr/bin/env bash
set -euo pipefail
FLUTTER_VERSION=3.50.0
if ! command -v flutter >/dev/null 2>&1; then
  SDK_DIR="$PWD/.cache/flutter"
  if [ ! -x "$SDK_DIR/bin/flutter" ]; then
    mkdir -p "$PWD/.cache"
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK_DIR"
  fi
  export PATH="$SDK_DIR/bin:$PATH"
fi
flutter config --no-analytics
flutter pub get --enforce-lockfile
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
