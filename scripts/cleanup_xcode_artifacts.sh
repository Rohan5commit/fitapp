#!/usr/bin/env bash
set -euo pipefail

FULL_SIM_CLEAN=0
if [[ "${1:-}" == "--full-sim" ]]; then
  FULL_SIM_CLEAN=1
fi

echo "Cleaning Xcode build artifacts..."
rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null || true
rm -rf "$HOME/Library/Developer/Xcode/Archives"/* 2>/dev/null || true

if command -v xcrun >/dev/null 2>&1; then
  echo "Removing unavailable simulators..."
  xcrun simctl delete unavailable >/dev/null 2>&1 || true

  if [[ "$FULL_SIM_CLEAN" -eq 1 ]]; then
    echo "Removing all simulator devices..."
    rm -rf "$HOME/Library/Developer/CoreSimulator/Devices"/* 2>/dev/null || true
  fi
fi

echo "Done."
echo "Tip: You can also remove unused platform runtimes from Xcode > Settings > Platforms."
