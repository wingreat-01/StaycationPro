#!/usr/bin/env bash
# Vercel has no Flutter preinstalled, so fetch the stable SDK for the build.
set -euo pipefail

if [ ! -d flutter ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git flutter
fi
flutter/bin/flutter --version
flutter/bin/flutter config --no-analytics
flutter/bin/flutter pub get
