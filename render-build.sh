#!/usr/bin/env bash
# Build de la app web para Render (Static Site).
# Render no trae Flutter, así que se descarga la versión fijada y se compila.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.38.5}"
FLUTTER_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/flutter-${FLUTTER_VERSION}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Descargando Flutter $FLUTTER_VERSION..."
  rm -rf "$FLUTTER_DIR"
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --disable-analytics >/dev/null 2>&1 || true
flutter config --no-analytics --enable-web
flutter --version

flutter pub get
flutter build web --release

echo "Build listo en build/web"
