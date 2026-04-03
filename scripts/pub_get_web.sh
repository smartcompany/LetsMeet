#!/usr/bin/env bash
# 웹용: path override 없이 pubspec.yaml 의 git share_lib 만 사용
set -euo pipefail
cd "$(dirname "$0")/.."
rm -f pubspec_overrides.yaml
flutter pub get "$@"
