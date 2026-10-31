#!/usr/bin/env bash
# Archive Pump Radar and upload it to TestFlight.
# Expects APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID,
# APP_STORE_CONNECT_KEY_P8, and APPLE_TEAM_ID in the environment.
# PRODUCT_BUNDLE_IDENTIFIER is optional and defaults to com.pumpradar.ios.

set -euo pipefail

KEY_ID="${APP_STORE_CONNECT_KEY_ID:?APP_STORE_CONNECT_KEY_ID is missing}"
ISSUER="${APP_STORE_CONNECT_ISSUER_ID:?APP_STORE_CONNECT_ISSUER_ID is missing}"
TEAM="${APPLE_TEAM_ID:?APPLE_TEAM_ID is missing}"
P8_CONTENT="${APP_STORE_CONNECT_KEY_P8:?APP_STORE_CONNECT_KEY_P8 is missing}"
BUNDLE_ID="${PRODUCT_BUNDLE_IDENTIFIER:-com.pumpradar.ios}"
BUILD_NUMBER="${GITHUB_RUN_NUMBER:-1}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p "$ROOT/private_keys" "$HOME/.private_keys" "$HOME/.appstoreconnect/private_keys" "$ROOT/build/export"
KEY_PATH="$ROOT/private_keys/AuthKey_${KEY_ID}.p8"

if printf '%s' "$P8_CONTENT" | grep -q "BEGIN PRIVATE KEY"; then
  printf '%s\n' "$P8_CONTENT" > "$KEY_PATH"
else
  printf '%s' "$P8_CONTENT" | tr -d ' \n\r\t' | base64 -D > "$KEY_PATH"
fi

if ! grep -q "BEGIN PRIVATE KEY" "$KEY_PATH"; then
  echo "The App Store Connect key could not be read."
  echo "Paste the .p8 text, including the BEGIN PRIVATE KEY line, or paste a base64 encoding of that file."
  exit 1
fi

chmod 600 "$KEY_PATH"
cp "$KEY_PATH" "$HOME/.private_keys/AuthKey_${KEY_ID}.p8"
cp "$KEY_PATH" "$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"

if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi
xcodegen generate

xcodebuild archive \
  -project PumpRadar.xcodeproj \
  -scheme PumpRadar \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ROOT/build/PumpRadar.xcarchive" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER" \
  DEVELOPMENT_TEAM="$TEAM" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGN_STYLE=Automatic \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  MARKETING_VERSION="0.1.0"

cat > "$ROOT/build/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>export</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${TEAM}</string>
  <key>uploadSymbols</key>
  <true/>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
  -archivePath "$ROOT/build/PumpRadar.xcarchive" \
  -exportPath "$ROOT/build/export" \
  -exportOptionsPlist "$ROOT/build/ExportOptions.plist" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER"

set +o pipefail
IPA="$(find "$ROOT/build/export" -name '*.ipa' | head -n 1)"
set -o pipefail
if [ -z "$IPA" ]; then
  echo "Export finished without an .ipa file."
  exit 1
fi
echo "Exported $(basename "$IPA")"

set +e
xcrun iTMSTransporter -m upload -assetFile "$IPA" -apiKey "$KEY_ID" -apiIssuer "$ISSUER" -v informational
TRANSPORTER_STATUS=$?
set -e

if [ "$TRANSPORTER_STATUS" -ne 0 ]; then
  echo "iTMSTransporter failed (${TRANSPORTER_STATUS}). Trying altool."
  xcrun altool --upload-app --type ios --file "$IPA" --apiKey "$KEY_ID" --apiIssuer "$ISSUER"
fi

echo "Upload submitted. App Store Connect still needs a few minutes to process the build before TestFlight shows it."
