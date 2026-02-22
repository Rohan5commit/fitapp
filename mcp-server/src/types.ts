export interface WorkoutHistoryItem {
  date: string;
  exercisesCompleted: number;
  totalVolume?: number;
  caloriesBurned?: number;
  avgHeartRate?: number;
  perceivedEffort?: number;
  notes?: string;
}

export interface AnalyzeTrendsRequest {
  workoutHistory: WorkoutHistoryItem[];
  goals: {
    primaryGoal: string;
    daysPerWeek: number;
    targetMetric?: string;
    notes?: string;
  };
}

export interface AnalyzeTrendsResponse {
  summary: string;
  wins: string[];
  risks: string[];
  recommendations: string[];
  overtrainingRisk: "low" | "moderate" | "high";
  plateauRisk: "low" | "moderate" | "high";
}

export interface GeneratePlanRequest {
  userProfile: {
    name: string;
    age: number;
    fitnessGoal: string;
    fitnessLevel: string;
  };
  preferences: {
    preferredWorkouts: string[];
    equipment: string[];
    daysPerWeek: number;
    sessionLengthMinutes?: number;
    limitations?: string[];
  };
}

export interface PlanExercise {
  name: string;
  sets: number;
  reps: string;
  duration?: number | null;
  restSeconds: number;
  muscleGroup: string;
  difficulty: string;
  notes?: string;
}

export interface PlanDay {
  dayOfWeek: string;
  focus: string;
  exercises: PlanExercise[];
}

export interface GeneratePlanResponse {
  weekStartDate: string;
  days: PlanDay[];
  rationale: string;
  recoveryTips: string[];
}

export interface RecommendAdjustmentsRequest {
  recentPerformance: {
    adherenceRate: number;
    averageEffort: number;
    sorenessLevel: number;
    fatigueLevel: number;
    notes?: string;
  };
  existingPlan: GeneratePlanResponse;
}

export interface RecommendAdjustmentsResponse {
  adjustments: Array<{
    dayOfWeek: string;
    action: string;
    reason: string;
  }>;
  deloadSuggested: boolean;
  deloadReason: string;
  nextCheckIn: string;
}
