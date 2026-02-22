import { Router } from "express";
import { ZodError } from "zod";
import { buildAdjustmentsPrompt } from "../ai/prompts.js";
import { ProviderResolver } from "../providerResolver.js";
import { RecommendAdjustmentsResponse } from "../types.js";
import { recommendAdjustmentsRequestSchema, recommendAdjustmentsResponseSchema } from "../validation.js";

export function buildRecommendAdjustmentsRouter(providerResolver: ProviderResolver): Router {
  const router = Router();

  router.post("/recommend-adjustments", async (req, res): Promise<void> => {
    let payload;
    try {
      payload = recommendAdjustmentsRequestSchema.parse(req.body);
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({ error: "Invalid request body", details: error.issues });
        return;
      }

      const message = error instanceof Error ? error.message : "Unknown error";
      res.status(400).json({ error: "Invalid request body", message });
      return;
    }

    try {
      const provider = providerResolver.resolve(req);
      const prompt = buildAdjustmentsPrompt(payload);
      const aiResponse = await provider.completeJSON<RecommendAdjustmentsResponse>(prompt);
      const response = recommendAdjustmentsResponseSchema.parse(aiResponse);
      res.json(response);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      res.status(500).json({ error: "Failed to recommend adjustments", message });
    }
  });

  return router;
}
