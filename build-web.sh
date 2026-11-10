#!/usr/bin/env bash
# Build de la app web (PWA) para Render, Vercel o local.
# Si Flutter $FLUTTER_VERSION ya está instalado lo usa; si no, lo descarga.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.38.5}"
FLUTTER_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/flutter-${FLUTTER_VERSION}"

# Flutter necesita unzip/xz para descargar el SDK de Dart. La imagen de
# Vercel (Amazon Linux) puede no traerlos: se instalan con dnf si hace falta.
for tool in unzip xz; do
  if ! command -v "$tool" >/dev/null 2>&1 && command -v dnf >/dev/null 2>&1; then
    echo "Instalando $tool..."
    dnf install -y "$tool" >/dev/null
  fi
done

if command -v flutter >/dev/null 2>&1 &&
  flutter --version 2>/dev/null | grep -q "Flutter $FLUTTER_VERSION"; then
  echo "Usando Flutter instalado ($FLUTTER_VERSION)"
else
  if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
    echo "Descargando Flutter $FLUTTER_VERSION..."
    rm -rf "$FLUTTER_DIR"
    git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

flutter --disable-analytics >/dev/null 2>&1 || true
flutter config --no-analytics --enable-web
flutter --version

flutter pub get
flutter build web --release --dart-define=PANEL_URL="${PANEL_URL:-}"

echo "Build listo en build/web"
