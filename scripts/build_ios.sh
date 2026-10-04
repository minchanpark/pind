#!/usr/bin/env bash
# Archive the iOS app with config/local.json baked in and upload it to
# TestFlight. Without --dart-define-from-file the app has no Supabase URL or
# keys, and login, map and search all fail (TestFlight builds 1 and 2).
# Usage: ASC_KEY_PATH=… ASC_KEY_ID=… ASC_ISSUER_ID=… scripts/build_ios.sh
# Bump the build number in pubspec.yaml first; App Store Connect rejects reuse.
set -euo pipefail
cd "$(dirname "$0")/.."

config=config/local.json
: "${ASC_KEY_PATH:?App Store Connect API key (.p8) path}"
: "${ASC_KEY_ID:?App Store Connect key id}"
: "${ASC_ISSUER_ID:?App Store Connect issuer id}"
for key in SUPABASE_URL SUPABASE_PUBLISHABLE_KEY GOOGLE_MAPS_API_KEY KAKAO_NATIVE_APP_KEY; do
  if ! grep -Eq "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]+" "$config"; then
    echo "$key is empty in $config; refusing to build an app that cannot reach the backend." >&2
    exit 1
  fi
done

auth=(-allowProvisioningUpdates -authenticationKeyPath "$ASC_KEY_PATH"
  -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
rm -rf build/ios/archive build/ios/export
flutter build ios --release --config-only --dart-define-from-file="$config"

# The defines must have reached Xcode, or the archive ships without them.
defines=$(grep '^DART_DEFINES=' ios/Flutter/Generated.xcconfig | cut -d= -f2- | tr ',' '\n' |
  while read -r d; do echo "$d" | base64 -d; echo; done)
grep -q '^SUPABASE_URL=https' <<<"$defines" || { echo "SUPABASE_URL did not reach Xcode." >&2; exit 1; }

xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/ios/archive/Runner.xcarchive \
  archive "${auth[@]}"

team=$(grep -m1 'DEVELOPMENT_TEAM = ' ios/Runner.xcodeproj/project.pbxproj | sed -E 's/.*= ([A-Z0-9]+);/\1/')
options=$(mktemp -t ExportOptions).plist
cat >"$options" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>$team</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
EOF
xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist "$options" -exportPath build/ios/export "${auth[@]}"
rm -f "$options"
