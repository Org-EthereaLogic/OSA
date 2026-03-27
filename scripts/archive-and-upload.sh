#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Lantern (OSA) — Archive, Export, and Upload to TestFlight
# ─────────────────────────────────────────────────────────────
#
# Usage:
#   ./scripts/archive-and-upload.sh --team-id YOUR_TEAM_ID
#
# Prerequisites:
#   - Full Xcode installed (not just Command Line Tools)
#   - Apple Developer account with App Store Connect access
#   - App ID "com.etherealogic.OSA" registered in the Developer Portal
#   - Authenticated to App Store Connect (run: xcrun notarytool store-credentials
#     or ensure Xcode is signed in to your Apple ID)
#
# What this script does:
#   1. Validates environment (Xcode, team ID, project)
#   2. Regenerates the Xcode project from project.yml
#   3. Builds and archives the app for distribution
#   4. Exports the archive as an App Store IPA
#   5. Uploads to App Store Connect / TestFlight
#
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEME="OSA"
PROJECT="$PROJECT_ROOT/OSA.xcodeproj"
ARCHIVE_DIR="$PROJECT_ROOT/build/archive"
EXPORT_DIR="$PROJECT_ROOT/build/export"
EXPORT_OPTIONS="$PROJECT_ROOT/ExportOptions.plist"
ARCHIVE_PATH="$ARCHIVE_DIR/OSA.xcarchive"

# ── Parse arguments ──────────────────────────────────────────

TEAM_ID=""
SKIP_UPLOAD=false
BUILD_NUMBER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --team-id)
            TEAM_ID="$2"
            shift 2
            ;;
        --skip-upload)
            SKIP_UPLOAD=true
            shift
            ;;
        --build-number)
            BUILD_NUMBER="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 --team-id TEAM_ID [--build-number N] [--skip-upload]"
            echo ""
            echo "  --team-id ID       Apple Developer Team ID (required)"
            echo "  --build-number N   Override CURRENT_PROJECT_VERSION (optional)"
            echo "  --skip-upload      Archive and export only, do not upload"
            echo ""
            echo "The team ID can be found at https://developer.apple.com/account"
            echo "under Membership Details."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ── Validate environment ─────────────────────────────────────

echo "=== Lantern Archive & Upload ==="
echo ""

if [[ -z "$TEAM_ID" ]]; then
    echo "Error: --team-id is required."
    echo "Find your team ID at https://developer.apple.com/account (Membership Details)."
    echo "Usage: $0 --team-id YOUR_TEAM_ID"
    exit 1
fi

XCODE_PATH="$(xcode-select -p 2>/dev/null || true)"
if [[ ! "$XCODE_PATH" == *"Xcode.app"* ]]; then
    echo "Error: Full Xcode is required. Current developer dir: $XCODE_PATH"
    echo "Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1
fi
echo "Xcode: $XCODE_PATH"

if [[ ! -f "$PROJECT_ROOT/project.yml" ]]; then
    echo "Error: project.yml not found. Run this script from the project root."
    exit 1
fi

if [[ ! -f "$EXPORT_OPTIONS" ]]; then
    echo "Error: ExportOptions.plist not found at $EXPORT_OPTIONS"
    exit 1
fi

echo "Team ID: $TEAM_ID"
echo "Project: $PROJECT"
echo ""

# ── Step 1: Regenerate Xcode project ────────────────────────

echo "Step 1/5: Regenerating Xcode project..."
if command -v xcodegen &>/dev/null; then
    (cd "$PROJECT_ROOT" && xcodegen generate)
else
    echo "Warning: xcodegen not found. Using existing .xcodeproj."
fi
echo ""

# ── Step 2: Clean build directory ────────────────────────────

echo "Step 2/5: Preparing build directories..."
rm -rf "$ARCHIVE_DIR" "$EXPORT_DIR"
mkdir -p "$ARCHIVE_DIR" "$EXPORT_DIR"
echo ""

# ── Step 3: Archive ──────────────────────────────────────────

echo "Step 3/5: Archiving..."

BUILD_SETTINGS=(
    DEVELOPMENT_TEAM="$TEAM_ID"
    CODE_SIGN_STYLE=Automatic
)

if [[ -n "$BUILD_NUMBER" ]]; then
    BUILD_SETTINGS+=(CURRENT_PROJECT_VERSION="$BUILD_NUMBER")
    echo "  Build number override: $BUILD_NUMBER"
fi

xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    "${BUILD_SETTINGS[@]}" \
    | tail -5

if [[ ! -d "$ARCHIVE_PATH" ]]; then
    echo "Error: Archive failed. No .xcarchive produced."
    exit 1
fi
echo "Archive: $ARCHIVE_PATH"
echo ""

# ── Step 4: Export IPA ───────────────────────────────────────

echo "Step 4/5: Exporting IPA for App Store..."

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    | tail -5

IPA_PATH="$(find "$EXPORT_DIR" -name '*.ipa' -print -quit)"
if [[ -z "$IPA_PATH" ]]; then
    echo "Error: Export failed. No .ipa produced."
    exit 1
fi
echo "IPA: $IPA_PATH"
echo ""

# ── Step 5: Upload to App Store Connect ──────────────────────

if [[ "$SKIP_UPLOAD" == true ]]; then
    echo "Step 5/5: Upload skipped (--skip-upload)."
    echo ""
    echo "=== Done ==="
    echo "Archive: $ARCHIVE_PATH"
    echo "IPA:     $IPA_PATH"
    echo ""
    echo "To upload manually:"
    echo "  xcrun altool --upload-app -f \"$IPA_PATH\" -t ios --apiKey KEY --apiIssuer ISSUER"
    echo "  or drag the .xcarchive into Xcode Organizer > Distribute App."
    exit 0
fi

echo "Step 5/5: Uploading to App Store Connect..."

xcrun altool --upload-app \
    -f "$IPA_PATH" \
    -t ios \
    --output-format json \
    2>&1 | tee "$EXPORT_DIR/upload-result.json"

UPLOAD_EXIT=$?
if [[ $UPLOAD_EXIT -ne 0 ]]; then
    echo ""
    echo "Upload may have failed. Check $EXPORT_DIR/upload-result.json"
    echo ""
    echo "Common fixes:"
    echo "  1. Authenticate: xcrun altool --store-password-in-keychain-item 'altool' -u EMAIL -p APP_SPECIFIC_PASSWORD"
    echo "  2. Or use API key: xcrun altool --upload-app -f IPA -t ios --apiKey KEY --apiIssuer ISSUER"
    echo "  3. Or upload via Xcode: open the .xcarchive in Organizer > Distribute App."
    exit 1
fi

echo ""
echo "=== Done ==="
echo "Archive:  $ARCHIVE_PATH"
echo "IPA:      $IPA_PATH"
echo "Upload:   Success — check App Store Connect for TestFlight processing status."
echo ""
echo "Next steps:"
echo "  1. Open App Store Connect > TestFlight and wait for processing (~15-30 min)"
echo "  2. Install on device via TestFlight"
echo "  3. Validate RC-5: FM generation quality with real corpus"
echo "  4. Validate RC-6: App Store binary acceptance"
echo "  5. Capture screenshots for App Store listing"
