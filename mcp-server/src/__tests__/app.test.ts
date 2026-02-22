import request from "supertest";
import { describe, expect, it } from "vitest";
import { createApp } from "../app.js";
import { AIProvider, CompletionInput } from "../ai/provider.js";

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

describe("MCP server app", () => {
  it("returns health status", async () => {
    const app = createApp(new StubProvider("stub", {}));
    const response = await request(app).get("/health");

    expect(response.status).toBe(200);
    expect(response.body.ok).toBe(true);
    expect(response.body.provider).toBe("stub");
  });

  it("validates generate-plan request payload", async () => {
    const app = createApp(new StubProvider("stub", {}));
    const response = await request(app)
      .post("/generate-plan")
      .send({ invalid: true });

    expect(response.status).toBe(400);
    expect(response.body.error).toBe("Invalid request body");
  });

  it("returns provider response for generate-plan", async () => {
    const app = createApp(
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
});
