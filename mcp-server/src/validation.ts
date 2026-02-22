import { z } from "zod";

export const analyzeTrendsRequestSchema = z.object({
  workoutHistory: z.array(
    z.object({
      date: z.string().min(1),
      exercisesCompleted: z.number().int().min(0),
      totalVolume: z.number().min(0).optional(),
      caloriesBurned: z.number().min(0).optional(),
      avgHeartRate: z.number().min(0).optional(),
      perceivedEffort: z.number().min(0).max(10).optional(),
      notes: z.string().optional()
    })
  ),
  goals: z.object({
    primaryGoal: z.string().min(1),
    daysPerWeek: z.number().int().min(1).max(7),
    targetMetric: z.string().optional(),
    notes: z.string().optional()
  })
});

const planExerciseSchema = z.object({
  name: z.string().min(1),
  sets: z.number().int().min(0),
  reps: z.string().min(1),
  duration: z.number().int().min(1).nullable().optional(),
  restSeconds: z.number().int().min(0),
  muscleGroup: z.string().min(1),
  difficulty: z.string().min(1),
  notes: z.string().optional()
});

export const generatePlanRequestSchema = z.object({
  userProfile: z.object({
    name: z.string().min(1),
    age: z.number().int().min(1),
    fitnessGoal: z.string().min(1),
    fitnessLevel: z.string().min(1)
  }),
  preferences: z.object({
    preferredWorkouts: z.array(z.string()).default([]),
    equipment: z.array(z.string()).default([]),
    daysPerWeek: z.number().int().min(1).max(7),
    sessionLengthMinutes: z.number().int().min(5).max(240).optional(),
    limitations: z.array(z.string()).optional()
  })
});

export const generatePlanResponseSchema = z.object({
  weekStartDate: z.string().min(1),
  days: z.array(
    z.object({
      dayOfWeek: z.string().min(1),
      focus: z.string().min(1),
      exercises: z.array(planExerciseSchema)
    })
  ).min(1),
  rationale: z.string().min(1),
  recoveryTips: z.array(z.string())
});

export const recommendAdjustmentsRequestSchema = z.object({
  recentPerformance: z.object({
    adherenceRate: z.number().min(0).max(100),
    averageEffort: z.number().min(0).max(10),
    sorenessLevel: z.number().min(0).max(10),
    fatigueLevel: z.number().min(0).max(10),
    notes: z.string().optional()
  }),
  existingPlan: generatePlanResponseSchema
});

export const analyzeTrendsResponseSchema = z.object({
  summary: z.string().min(1),
  wins: z.array(z.string()),
  risks: z.array(z.string()),
  recommendations: z.array(z.string()),
  overtrainingRisk: z.enum(["low", "moderate", "high"]),
  plateauRisk: z.enum(["low", "moderate", "high"])
});

export const recommendAdjustmentsResponseSchema = z.object({
  adjustments: z.array(
    z.object({
      dayOfWeek: z.string().min(1),
      action: z.string().min(1),
      reason: z.string().min(1)
    })
  ),
  deloadSuggested: z.boolean(),
  deloadReason: z.string().min(1),
  nextCheckIn: z.string().min(1)
});
