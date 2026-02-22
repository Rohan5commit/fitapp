import { Router } from "express";
import { ZodError } from "zod";
import { AIProvider } from "../ai/provider.js";
import { buildAdjustmentsPrompt } from "../ai/prompts.js";
import { RecommendAdjustmentsResponse } from "../types.js";
import { recommendAdjustmentsRequestSchema, recommendAdjustmentsResponseSchema } from "../validation.js";

export function buildRecommendAdjustmentsRouter(provider: AIProvider): Router {
  const router = Router();

  router.post("/recommend-adjustments", async (req, res) => {
    try {
      const payload = recommendAdjustmentsRequestSchema.parse(req.body);
      const prompt = buildAdjustmentsPrompt(payload);
      const aiResponse = await provider.completeJSON<RecommendAdjustmentsResponse>(prompt);
      const response = recommendAdjustmentsResponseSchema.parse(aiResponse);
      res.json(response);
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({ error: "Invalid request body", details: error.issues });
        return;
      }

      const message = error instanceof Error ? error.message : "Unknown error";
      res.status(500).json({ error: "Failed to recommend adjustments", message });
    }
  });

  return router;
}
