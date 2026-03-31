#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_ID="${OSA_WEEK_SIM_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
DESTINATION="${OSA_WEEK_SIM_DESTINATION:-platform=iOS Simulator,name=iPhone 16}"
ARTIFACT_ROOT="$ROOT_DIR/build/week-sim/$RUN_ID"
RESULT_BUNDLE_PATH="$ARTIFACT_ROOT/OSAWeekInLifeSimulation.xcresult"
LOG_PATH="$ARTIFACT_ROOT/xcodebuild.log"

mkdir -p "$ARTIFACT_ROOT"

export OSA_WEEK_SIM_ARTIFACT_ROOT="$ARTIFACT_ROOT"
export OSA_WEEK_SIM_RUN_ID="$RUN_ID"

cd "$ROOT_DIR"

set +e
xcodebuild \
  -project OSA.xcodeproj \
  -scheme OSA \
  -destination "$DESTINATION" \
  -only-testing:OSAUITests/OSAWeekInLifeSimulationTests \
  -resultBundlePath "$RESULT_BUNDLE_PATH" \
  test | tee "$LOG_PATH"
TEST_EXIT=${PIPESTATUS[0]}
set -e

if [[ -d "$RESULT_BUNDLE_PATH" ]]; then
  ATTACHMENT_EXPORT_PATH="$ARTIFACT_ROOT/xcresult-attachments"
  mkdir -p "$ATTACHMENT_EXPORT_PATH"
  xcrun xcresulttool export attachments \
    --path "$RESULT_BUNDLE_PATH" \
    --output-path "$ATTACHMENT_EXPORT_PATH" >/dev/null || true
fi

RUNNER_CONTAINER="$(xcrun simctl get_app_container booted com.etherealogic.OSAUITests.xctrunner data 2>/dev/null || true)"
if [[ -n "$RUNNER_CONTAINER" ]]; then
  REPORTER_ROOT="$RUNNER_CONTAINER/tmp/OSAWeekSimulationReporter/$RUN_ID"
  if [[ -d "$REPORTER_ROOT" ]]; then
    cp -R "$REPORTER_ROOT"/. "$ARTIFACT_ROOT"/
  else
    FALLBACK_REPORTER_ROOT="$(find "$RUNNER_CONTAINER/tmp/OSAWeekSimulationReporter" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1)"
    if [[ -n "$FALLBACK_REPORTER_ROOT" && -d "$FALLBACK_REPORTER_ROOT" ]]; then
      cp -R "$FALLBACK_REPORTER_ROOT"/. "$ARTIFACT_ROOT"/
    fi
  fi
fi

printf '\nArtifacts:\n'
printf '  timeline: %s\n' "$ARTIFACT_ROOT/timeline.json"
printf '  summary:  %s\n' "$ARTIFACT_ROOT/summary.md"
printf '  result:   %s\n' "$RESULT_BUNDLE_PATH"
printf '  log:      %s\n' "$LOG_PATH"
exit "$TEST_EXIT"
