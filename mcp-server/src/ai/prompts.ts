import { AnalyzeTrendsRequest, GeneratePlanRequest, RecommendAdjustmentsRequest } from "../types.js";
import { CompletionInput } from "./provider.js";

export function buildAnalyzeTrendsPrompt(payload: AnalyzeTrendsRequest): CompletionInput {
  return {
    systemPrompt:
      "You are a strength and conditioning coach. Analyze trend data and provide practical, safe recommendations.",
    userPrompt: `Analyze this workout history and goals:\n${JSON.stringify(payload, null, 2)}`,
    schemaHint: JSON.stringify(
      {
        summary: "string",
        wins: ["string"],
        risks: ["string"],
        recommendations: ["string"],
        overtrainingRisk: "low|moderate|high",
        plateauRisk: "low|moderate|high"
      },
      null,
      2
    )
  };
}

export function buildGeneratePlanPrompt(payload: GeneratePlanRequest): CompletionInput {
  return {
    systemPrompt:
      "You are an expert personal trainer. Build a one-week personalized plan with progressive overload and recovery balance.",
    userPrompt: `Generate a 7-day workout plan from:\n${JSON.stringify(payload, null, 2)}`,
    schemaHint: JSON.stringify(
      {
        weekStartDate: "ISO-8601 date string",
        days: [
          {
            dayOfWeek: "Monday",
            focus: "Upper Body",
            exercises: [
              {
                name: "Bench Press",
                sets: 4,
                reps: "6-8",
                duration: null,
                restSeconds: 120,
                muscleGroup: "Chest",
                difficulty: "Intermediate",
                notes: "Optional string"
              }
            ]
          }
        ],
        rationale: "string",
        recoveryTips: ["string"]
      },
      null,
      2
    )
  };
}

export function buildAdjustmentsPrompt(payload: RecommendAdjustmentsRequest): CompletionInput {
  return {
    systemPrompt:
      "You are a recovery-focused coach. Recommend adjustments to reduce injury risk while preserving progress.",
    userPrompt: `Recommend adjustments from this performance context:\n${JSON.stringify(payload, null, 2)}`,
    schemaHint: JSON.stringify(
      {
        adjustments: [
          {
            dayOfWeek: "Tuesday",
            action: "Reduce lower-body volume by 20%",
            reason: "High soreness and fatigue signals"
          }
        ],
        deloadSuggested: true,
        deloadReason: "string",
        nextCheckIn: "ISO-8601 date string"
      },
      null,
      2
    )
  };
}
