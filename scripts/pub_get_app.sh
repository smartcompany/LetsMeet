#!/usr/bin/env bash
# 앱(iOS/Android)용: 로컬 ../../flutter_share_lib 패치를 쓰도록 override 생성 후 pub get
set -euo pipefail
cd "$(dirname "$0")/.."
cp -f pubspec_overrides.yaml.example pubspec_overrides.yaml
flutter pub get "$@"
