#!/bin/bash
# Build, install and launch Tend on a simulator with the design's sample data.
# Usage: scripts/sim.sh [extra launch args...]   e.g. scripts/sim.sh -startRoute mood
# Set SIM to a simulator UDID (defaults to the first booted iPhone). Set NOBUILD=1 to skip building.
set -euo pipefail
cd "$(dirname "$0")/.."
SIM=${SIM:-$(xcrun simctl list devices booted | grep -m1 -oE '[0-9A-F-]{36}')}
if [ -z "${NOBUILD:-}" ]; then
  xcodebuild build -project Practices.xcodeproj -scheme Practices -destination "platform=iOS Simulator,id=$SIM" \
    -derivedDataPath build/DerivedData > build/sim.log 2>&1 || { grep -E "error:" build/sim.log | head -20; exit 1; }
  grep -E "\.swift:[0-9]+:[0-9]+: warning" build/sim.log | sort -u || true
fi
xcrun simctl install "$SIM" build/DerivedData/Build/Products/Debug-iphonesimulator/Practices.app
xcrun simctl terminate "$SIM" com.lucasvilela.practices 2>/dev/null || true
xcrun simctl launch "$SIM" com.lucasvilela.practices -sampleData -firstName Lucas -didAskForName YES "$@" > /dev/null
echo "Launched on $SIM $*"
