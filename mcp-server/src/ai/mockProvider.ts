import { AppConfig } from "../config.js";
import { AIProvider, CompletionInput } from "./provider.js";

type AnyJSON = Record<string, unknown>;

function startOfWeekISO(referenceDate: Date = new Date()): string {
  const date = new Date(referenceDate);
  const day = date.getUTCDay();
  const diff = day === 0 ? -6 : 1 - day;
  date.setUTCDate(date.getUTCDate() + diff);
  date.setUTCHours(0, 0, 0, 0);
  return date.toISOString();
}

export class MockProvider implements AIProvider {
  readonly name = "mock";

  constructor(private readonly config: AppConfig) {}

  async completeJSON<T>(input: CompletionInput): Promise<T> {
    if (input.schemaHint.includes("overtrainingRisk") && input.schemaHint.includes("plateauRisk")) {
      return this.mockAnalyzeTrends() as T;
    }

    if (input.schemaHint.includes("recoveryTips") && input.schemaHint.includes("weekStartDate")) {
      return this.mockGeneratePlan() as T;
    }

    if (input.schemaHint.includes("deloadSuggested") && input.schemaHint.includes("nextCheckIn")) {
      return this.mockAdjustments() as T;
    }

    throw new Error("Mock provider could not infer response type from schemaHint.");
  }

  private mockAnalyzeTrends(): AnyJSON {
    if (this.config.mockScenario === "recovery") {
      return {
        summary: "Training load is elevated while recovery markers are trending down.",
        wins: ["Consistency remains strong over the past week."],
        risks: ["Accumulated fatigue is rising.", "Reduced session quality indicates recovery debt."],
        recommendations: ["Insert one active recovery day.", "Reduce lower-body volume by 15% this week."],
        overtrainingRisk: "moderate",
        plateauRisk: "moderate"
      };
    }

    if (this.config.mockScenario === "performance") {
      return {
        summary: "Performance trend is positive with manageable fatigue.",
        wins: ["Progressive overload is working.", "Adherence is high."],
        risks: ["Minor risk of shoulder overload from pushing frequency."],
        recommendations: ["Maintain current split.", "Add one mobility block for shoulders."],
        overtrainingRisk: "low",
        plateauRisk: "low"
      };
    }

    return {
      summary: "Training is stable with moderate room for optimization.",
      wins: ["Good consistency.", "Balanced exercise selection."],
      risks: ["Possible plateau in cardio sessions."],
      recommendations: ["Progress cardio intervals by 5 minutes.", "Track RPE for each workout."],
      overtrainingRisk: "low",
      plateauRisk: "moderate"
    };
  }

  private mockGeneratePlan(): AnyJSON {
    const baseDay = {
      focus: "Strength",
      exercises: [
        {
          name: "Goblet Squat",
          sets: 4,
          reps: "8-10",
          duration: null,
          restSeconds: 90,
          muscleGroup: "Legs",
          difficulty: "Intermediate",
          notes: "Use controlled tempo."
        },
        {
          name: "Push-Up",
          sets: 3,
          reps: "10-15",
          duration: null,
          restSeconds: 60,
          muscleGroup: "Chest",
          difficulty: "Beginner",
          notes: "Elevate hands if needed."
        }
      ]
    };

    return {
      weekStartDate: startOfWeekISO(),
      days: [
        { dayOfWeek: "Monday", ...baseDay },
        {
          dayOfWeek: "Wednesday",
          focus: "Conditioning",
          exercises: [
            {
              name: "Bike Intervals",
              sets: 6,
              reps: "45s hard / 75s easy",
              duration: 720,
              restSeconds: 30,
              muscleGroup: "Cardio",
              difficulty: "Intermediate",
              notes: "Keep cadence high in work intervals."
            },
            {
              name: "Plank",
              sets: 3,
              reps: "45s",
              duration: 135,
              restSeconds: 45,
              muscleGroup: "Core",
              difficulty: "Beginner",
              notes: "Focus on neutral spine."
            }
          ]
        },
        {
          dayOfWeek: "Friday",
          focus: "Upper Body",
          exercises: [
            {
              name: "Dumbbell Row",
              sets: 4,
              reps: "8-12",
              duration: null,
              restSeconds: 90,
              muscleGroup: "Back",
              difficulty: "Intermediate",
              notes: "Pause at top of each rep."
            },
            {
              name: "Overhead Press",
              sets: 3,
              reps: "6-10",
              duration: null,
              restSeconds: 90,
              muscleGroup: "Shoulders",
              difficulty: "Intermediate",
              notes: "Brace core before each rep."
            }
          ]
        }
      ],
      rationale: "Alternates strength and conditioning with recovery spacing for sustainable progression.",
      recoveryTips: [
        "Sleep 7-9 hours nightly.",
        "Take a 15-minute walk on non-training days.",
        "Prioritize protein intake post-workout."
      ]
    };
  }

  private mockAdjustments(): AnyJSON {
    const next = new Date();
    next.setDate(next.getDate() + 7);

    if (this.config.mockScenario === "recovery") {
      return {
        adjustments: [
          {
            dayOfWeek: "Wednesday",
            action: "Reduce total sets by 20%",
            reason: "Elevated fatigue and soreness indicate incomplete recovery."
          },
          {
            dayOfWeek: "Friday",
            action: "Replace heavy lower-body accessory with mobility work",
            reason: "Protect recovery while maintaining movement quality."
          }
        ],
        deloadSuggested: true,
        deloadReason: "Fatigue markers are consistently high.",
        nextCheckIn: next.toISOString()
      };
    }

    return {
      adjustments: [
        {
          dayOfWeek: "Monday",
          action: "Increase top set load by 2.5-5%",
          reason: "Strong adherence and stable fatigue support progression."
        }
      ],
      deloadSuggested: false,
      deloadReason: "Current recovery profile supports normal progression.",
      nextCheckIn: next.toISOString()
    };
  }
}
