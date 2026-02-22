import { Router } from "express";
import { ZodError } from "zod";
import { AIProvider } from "../ai/provider.js";
import { buildAnalyzeTrendsPrompt } from "../ai/prompts.js";
import { AnalyzeTrendsResponse } from "../types.js";
import { analyzeTrendsRequestSchema, analyzeTrendsResponseSchema } from "../validation.js";

export function buildAnalyzeTrendsRouter(provider: AIProvider): Router {
  const router = Router();

  router.post("/analyze-trends", async (req, res) => {
    try {
      const payload = analyzeTrendsRequestSchema.parse(req.body);
      const prompt = buildAnalyzeTrendsPrompt(payload);
      const aiResponse = await provider.completeJSON<AnalyzeTrendsResponse>(prompt);
      const response = analyzeTrendsResponseSchema.parse(aiResponse);
      res.json(response);
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({ error: "Invalid request body", details: error.issues });
        return;
      }

      const message = error instanceof Error ? error.message : "Unknown error";
      res.status(500).json({ error: "Failed to analyze trends", message });
    }
  });

  return router;
}
