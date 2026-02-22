import { Router } from "express";
import { ZodError } from "zod";
import { AIProvider } from "../ai/provider.js";
import { buildGeneratePlanPrompt } from "../ai/prompts.js";
import { GeneratePlanResponse } from "../types.js";
import { generatePlanRequestSchema, generatePlanResponseSchema } from "../validation.js";

export function buildGeneratePlanRouter(provider: AIProvider): Router {
  const router = Router();

  router.post("/generate-plan", async (req, res) => {
    let payload;
    try {
      payload = generatePlanRequestSchema.parse(req.body);
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
      const prompt = buildGeneratePlanPrompt(payload);
      const aiResponse = await provider.completeJSON<GeneratePlanResponse>(prompt);
      const response = generatePlanResponseSchema.parse(aiResponse);
      res.json(response);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      res.status(500).json({ error: "Failed to generate plan", message });
    }
  });

  return router;
}
