import { Router } from "express";
import { ZodError } from "zod";
import { buildAnalyzeTrendsPrompt } from "../ai/prompts.js";
import { ProviderResolver } from "../providerResolver.js";
import { AnalyzeTrendsResponse } from "../types.js";
import { analyzeTrendsRequestSchema, analyzeTrendsResponseSchema } from "../validation.js";

export function buildAnalyzeTrendsRouter(providerResolver: ProviderResolver): Router {
  const router = Router();

  router.post("/analyze-trends", async (req, res): Promise<void> => {
    let payload;
    try {
      payload = analyzeTrendsRequestSchema.parse(req.body);
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
      const prompt = buildAnalyzeTrendsPrompt(payload);
      const aiResponse = await provider.completeJSON<AnalyzeTrendsResponse>(prompt);
      const response = analyzeTrendsResponseSchema.parse(aiResponse);
      res.json(response);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      res.status(500).json({ error: "Failed to analyze trends", message });
    }
  });

  return router;
}
