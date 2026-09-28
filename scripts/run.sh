#!/usr/bin/env bash
# Run the Pind app with Supabase and Google Maps from config/local.json.
# Usage: scripts/run.sh [device-id] [extra flutter run args...]
#   scripts/run.sh                 # pick a device interactively
#   scripts/run.sh ios             # first booted iOS simulator
#   scripts/run.sh emulator-5554   # a specific device (see: flutter devices)
set -euo pipefail
cd "$(dirname "$0")/.."

config=config/local.json
if [[ ! -f $config ]]; then
  echo "Missing $config. Copy config/example.json and fill in the keys." >&2
  exit 1
fi
# The native Maps SDK key comes from this define; an empty key shows no map.
if ! grep -Eq '"GOOGLE_MAPS_API_KEY"[[:space:]]*:[[:space:]]*"[^"]+' "$config"; then
  echo "GOOGLE_MAPS_API_KEY is empty in $config; the map will not render." >&2
  exit 1
fi

device=()
if [[ ${1:-} == ios ]]; then
  shift
  id=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1 || true)
  if [[ -z $id ]]; then
    open -a Simulator
    echo "No booted iOS simulator. Opened Simulator; boot a device and retry." >&2
    exit 1
  fi
  device=(-d "$id")
elif [[ $# -gt 0 && $1 != -* ]]; then
  device=(-d "$1")
  shift
fi

flutter pub get
exec flutter run -t lib/main.dart --dart-define-from-file="$config" ${device[@]+"${device[@]}"} "$@"
