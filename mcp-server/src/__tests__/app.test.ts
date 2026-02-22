import request from "supertest";
import { describe, expect, it } from "vitest";
import { createApp } from "../app.js";
import { AIProvider, CompletionInput } from "../ai/provider.js";
import { ProviderResolver } from "../providerResolver.js";

class StubProvider implements AIProvider {
  readonly name: string;
  private readonly response: unknown;

  constructor(name: string, response: unknown) {
    this.name = name;
    this.response = response;
  }

  async completeJSON<T>(_input: CompletionInput): Promise<T> {
    return this.response as T;
  }
}

function makeResolver(provider: AIProvider): ProviderResolver {
  return {
    defaultProvider: provider,
    resolve: () => provider
  };
}

describe("MCP server app", () => {
  it("returns health status", async () => {
    const app = createApp(makeResolver(new StubProvider("stub", {})));
    const response = await request(app).get("/health");

    expect(response.status).toBe(200);
    expect(response.body.ok).toBe(true);
    expect(response.body.provider).toBe("stub");
  });

  it("validates generate-plan request payload", async () => {
    const app = createApp(makeResolver(new StubProvider("stub", {})));
    const response = await request(app)
      .post("/generate-plan")
      .send({ invalid: true });

    expect(response.status).toBe(400);
    expect(response.body.error).toBe("Invalid request body");
  });

  it("returns provider response for generate-plan", async () => {
    const app = createApp(
      makeResolver(
        new StubProvider("stub", {
          weekStartDate: "2026-02-23T00:00:00.000Z",
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
                  notes: "Maintain bar path"
                }
              ]
            }
          ],
          rationale: "Balanced weekly structure.",
          recoveryTips: ["Hydrate", "Sleep"]
        })
      )
    );

    const response = await request(app)
      .post("/generate-plan")
      .send({
        userProfile: {
          name: "Rohan",
          age: 30,
          fitnessGoal: "Build Muscle",
          fitnessLevel: "Intermediate"
        },
        preferences: {
          preferredWorkouts: ["Strength"],
          equipment: ["Dumbbells"],
          daysPerWeek: 4,
          sessionLengthMinutes: 45
        }
      });

    expect(response.status).toBe(200);
    expect(response.body.days.length).toBe(1);
    expect(response.body.days[0].exercises[0].name).toBe("Bench Press");
  });

  it("returns response for analyze-trends", async () => {
    const app = createApp(
      makeResolver(
        new StubProvider("stub", {
          summary: "Good consistency",
          wins: ["Adherence improved"],
          risks: ["Slight fatigue accumulation"],
          recommendations: ["Add one mobility block"],
          overtrainingRisk: "low",
          plateauRisk: "moderate"
        })
      )
    );

    const response = await request(app)
      .post("/analyze-trends")
      .send({
        workoutHistory: [
          {
            date: "2026-02-20T00:00:00.000Z",
            exercisesCompleted: 5,
            totalVolume: 10100
          }
        ],
        goals: {
          primaryGoal: "Build Muscle",
          daysPerWeek: 4
        }
      });

    expect(response.status).toBe(200);
    expect(response.body.summary).toBe("Good consistency");
  });

  it("returns response for recommend-adjustments", async () => {
    const app = createApp(
      makeResolver(
        new StubProvider("stub", {
          adjustments: [
            {
              dayOfWeek: "Wednesday",
              action: "Reduce volume by 10%",
              reason: "Mild fatigue trend"
            }
          ],
          deloadSuggested: false,
          deloadReason: "Fatigue trend is manageable.",
          nextCheckIn: "2026-03-02T00:00:00.000Z"
        })
      )
    );

    const response = await request(app)
      .post("/recommend-adjustments")
      .send({
        recentPerformance: {
          adherenceRate: 90,
          averageEffort: 7,
          sorenessLevel: 4,
          fatigueLevel: 5
        },
        existingPlan: {
          weekStartDate: "2026-02-23T00:00:00.000Z",
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
                  difficulty: "Intermediate"
                }
              ]
            }
          ],
          rationale: "Balanced split",
          recoveryTips: ["Hydrate"]
        }
      });

    expect(response.status).toBe(200);
    expect(response.body.adjustments[0].dayOfWeek).toBe("Wednesday");
  });

  it("returns 500 when provider response fails schema", async () => {
    const app = createApp(makeResolver(new StubProvider("stub", { invalid: true })));

    const response = await request(app)
      .post("/generate-plan")
      .send({
        userProfile: {
          name: "Rohan",
          age: 30,
          fitnessGoal: "Build Muscle",
          fitnessLevel: "Intermediate"
        },
        preferences: {
          preferredWorkouts: ["Strength"],
          equipment: ["Dumbbells"],
          daysPerWeek: 4
        }
      });

    expect(response.status).toBe(500);
    expect(response.body.error).toBe("Failed to generate plan");
  });

  it("can resolve provider per request", async () => {
    const defaultProvider = new StubProvider("default", {
      weekStartDate: "2026-02-23T00:00:00.000Z",
      days: [
        {
          dayOfWeek: "Monday",
          focus: "Upper Body",
          exercises: [
            {
              name: "Default Press",
              sets: 4,
              reps: "6-8",
              duration: null,
              restSeconds: 120,
              muscleGroup: "Chest",
              difficulty: "Intermediate"
            }
          ]
        }
      ],
      rationale: "Default provider path.",
      recoveryTips: ["Hydrate"]
    });

    const overrideProvider = new StubProvider("override", {
      weekStartDate: "2026-02-23T00:00:00.000Z",
      days: [
        {
          dayOfWeek: "Monday",
          focus: "Upper Body",
          exercises: [
            {
              name: "Override Press",
              sets: 4,
              reps: "6-8",
              duration: null,
              restSeconds: 120,
              muscleGroup: "Chest",
              difficulty: "Intermediate"
            }
          ]
        }
      ],
      rationale: "Override provider path.",
      recoveryTips: ["Sleep"]
    });

    const resolver: ProviderResolver = {
      defaultProvider,
      resolve(req) {
        return req.header("x-test-provider") === "override" ? overrideProvider : defaultProvider;
      }
    };

    const app = createApp(resolver);

    const defaultResponse = await request(app)
      .post("/generate-plan")
      .send({
        userProfile: {
          name: "Rohan",
          age: 30,
          fitnessGoal: "Build Muscle",
          fitnessLevel: "Intermediate"
        },
        preferences: {
          preferredWorkouts: ["Strength"],
          equipment: ["Dumbbells"],
          daysPerWeek: 4
        }
      });

    expect(defaultResponse.status).toBe(200);
    expect(defaultResponse.body.days[0].exercises[0].name).toBe("Default Press");

    const overrideResponse = await request(app)
      .post("/generate-plan")
      .set("x-test-provider", "override")
      .send({
        userProfile: {
          name: "Rohan",
          age: 30,
          fitnessGoal: "Build Muscle",
          fitnessLevel: "Intermediate"
        },
        preferences: {
          preferredWorkouts: ["Strength"],
          equipment: ["Dumbbells"],
          daysPerWeek: 4
        }
      });

    expect(overrideResponse.status).toBe(200);
    expect(overrideResponse.body.days[0].exercises[0].name).toBe("Override Press");
  });
});
