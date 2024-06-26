PLATFORM_IOS := "iOS Simulator,name=iPhone 15 Pro"
PLATFORM_MACOS := "macOS"
PLATFORM_MAC_CATALYST := "macOS,variant=Mac Catalyst"
PLATFORM_TVOS := "tvOS Simulator,name=Apple TV"
PLATFORM_WATCHOS := "watchOS Simulator,name=Apple Watch Series 9 (41mm)"

SCHEME := "swift-tca-extras"
CONFIG := "debug"
DOCC_TARGET := "TCAExtras"

test-ios:
  set -o pipefail && \
  xcodebuild test \
    -skipMacroValidation \
    -scheme {{SCHEME}} \
    -configuration {{CONFIG}} \
    -destination platform='{{PLATFORM_IOS}}'

test-macos:
  set -o pipefail && \
  xcodebuild test \
    -skipMacroValidation \
    -scheme {{SCHEME}} \
    -configuration {{CONFIG}} \
    -destination platform='{{PLATFORM_MACOS}}'

test-mac-catalyst:
  set -o pipefail && \
  xcodebuild test \
    -skipMacroValidation \
    -scheme {{SCHEME}} \
    -configuration {{CONFIG}} \
    -destination platform='{{PLATFORM_MAC_CATALYST}}'

test-tvos:
  set -o pipefail && \
  xcodebuild test \
    -skipMacroValidation \
    -scheme {{SCHEME}} \
    -configuration {{CONFIG}} \
    -destination platform='{{PLATFORM_TVOS}}'

test-watchos:
  set -o pipefail && \
  xcodebuild test \
    -skipMacroValidation \
    -scheme {{SCHEME}} \
    -configuration {{CONFIG}} \
    -destination platform='{{PLATFORM_WATCHOS}}'

test-all: test-ios test-macos test-mac-catalyst test-tvos test-watchos

test-swift:
  @swift test

format:
  @swiftformat .

build-documentation:
  @swift package \
    --allow-writing-to-directory ./docs \
    generate-documentation \
    --target {{DOCC_TARGET}} \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path swift-tca-extras \
    --output-path ./docs

preview-documentation:
  @swift package \
    --disable-sandbox \
    preview-documentation \
    --target {{DOCC_TARGET}}
