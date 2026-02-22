# MCP API Examples

Base URL: `http://127.0.0.1:8787`

Formal OpenAPI contract: `docs/openapi.yaml`

## `GET /health`

Example response:

```json
{
  "ok": true,
  "provider": "mock",
  "timestamp": "2026-02-22T00:00:00.000Z"
}
```

## `POST /analyze-trends`

Optional headers for provider override:

```http
x-fitmind-provider: openai|claude|mock
x-fitmind-openai-key: sk-...
x-fitmind-anthropic-key: ...
x-fitmind-mock-scenario: balanced|recovery|performance
```

Request:

```json
{
  "workoutHistory": [
    {
      "date": "2026-02-15T18:00:00.000Z",
      "exercisesCompleted": 6,
      "totalVolume": 12450,
      "caloriesBurned": 510,
      "avgHeartRate": 138,
      "perceivedEffort": 7,
      "notes": "Felt strong on compounds"
    }
  ],
  "goals": {
    "primaryGoal": "Build Muscle",
    "daysPerWeek": 4,
    "targetMetric": "Increase squat 1RM",
    "notes": "Prioritize lower body"
  }
}
```

## `POST /generate-plan`

Optional headers are the same as `/analyze-trends`.

Request:

```json
{
  "userProfile": {
    "name": "Rohan",
    "age": 30,
    "fitnessGoal": "Build Muscle",
    "fitnessLevel": "Intermediate"
  },
  "preferences": {
    "preferredWorkouts": ["Strength", "HIIT"],
    "equipment": ["Dumbbells", "Barbell"],
    "daysPerWeek": 4,
    "sessionLengthMinutes": 50,
    "limitations": ["Mild shoulder impingement"]
  }
}
```

## `POST /recommend-adjustments`

Optional headers are the same as `/analyze-trends`.

Request:

```json
{
  "recentPerformance": {
    "adherenceRate": 88,
    "averageEffort": 7.2,
    "sorenessLevel": 5.0,
    "fatigueLevel": 6.0,
    "notes": "Legs very fatigued after Friday"
  },
  "existingPlan": {
    "weekStartDate": "2026-02-23T00:00:00.000Z",
    "days": [
      {
        "dayOfWeek": "Monday",
        "focus": "Upper Body",
        "exercises": [
          {
            "name": "Bench Press",
            "sets": 4,
            "reps": "6-8",
            "duration": null,
            "restSeconds": 120,
            "muscleGroup": "Chest",
            "difficulty": "Intermediate",
            "notes": "Maintain bar path"
          }
        ]
      }
    ],
    "rationale": "Balanced split",
    "recoveryTips": ["Hydrate", "Sleep"]
  }
}
```
