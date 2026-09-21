#!/bin/zsh

set -ex

flutter build macos --release
APP_NAME="build/macos/Build/Products/Release/FossFit.app"
PACKAGE_NAME=build/macos/FossFit.pkg
xcrun productbuild --component "$APP_NAME" /Applications/ build/macos/unsigned.pkg
INSTALLER_CERT_NAME=$(keychain list-certificates |
  jq '[.[]
            | select(.common_name
            | contains("Mac Developer Installer"))
            | .common_name][0]' |
  xargs)
xcrun productsign --sign "$INSTALLER_CERT_NAME" build/macos/unsigned.pkg "$PACKAGE_NAME"
rm -f build/macos/unsigned.pkg

fastlane deliver --pkg build/macos/FossFit.pkg || true
flutter build ipa
fastlane deliver --ipa build/ios/ipa/FossFit.ipa
