import cors from "cors";
import express from "express";
import { AIProvider } from "./ai/provider.js";
import { buildAnalyzeTrendsRouter } from "./routes/analyzeTrends.js";
import { buildGeneratePlanRouter } from "./routes/generatePlan.js";
import { buildRecommendAdjustmentsRouter } from "./routes/recommendAdjustments.js";

export function createApp(provider: AIProvider): express.Express {
  const app = express();

  app.use(cors());
  app.use(express.json({ limit: "1mb" }));

  app.use((req, _res, next) => {
    req.setTimeout(30_000);
    next();
  });

  app.get("/health", (_req, res) => {
    res.json({
      ok: true,
      provider: provider.name,
      timestamp: new Date().toISOString()
    });
  });

  app.use(buildAnalyzeTrendsRouter(provider));
  app.use(buildGeneratePlanRouter(provider));
  app.use(buildRecommendAdjustmentsRouter(provider));

  app.use((_req, res) => {
    res.status(404).json({ error: "Not found" });
  });

  app.use((error: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
    const message = error instanceof Error ? error.message : "Internal server error";
    res.status(500).json({ error: "Internal server error", message });
  });

  return app;
}
