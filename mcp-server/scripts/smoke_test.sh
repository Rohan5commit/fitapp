#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:8787}"

echo "[smoke] GET ${BASE_URL}/health"
curl -fsSL "${BASE_URL}/health" | sed -e 's/^/[health] /'

echo "[smoke] POST ${BASE_URL}/generate-plan"
curl -fsSL -X POST "${BASE_URL}/generate-plan" \
  -H 'content-type: application/json' \
  -d '{
    "userProfile": {
      "name": "Rohan",
      "age": 30,
      "fitnessGoal": "Build Muscle",
      "fitnessLevel": "Intermediate"
    },
    "preferences": {
      "preferredWorkouts": ["Strength"],
      "equipment": ["Dumbbells"],
      "daysPerWeek": 4,
      "sessionLengthMinutes": 45
    }
  }' | sed -e 's/^/[generate-plan] /'

echo "[smoke] done"
