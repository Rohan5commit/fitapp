import "dotenv/config";
import cors from "cors";
import express from "express";
import { loadConfig } from "./config.js";
import { ClaudeProvider } from "./ai/claudeProvider.js";
import { OpenAIProvider } from "./ai/openaiProvider.js";
import { buildAnalyzeTrendsRouter } from "./routes/analyzeTrends.js";
import { buildGeneratePlanRouter } from "./routes/generatePlan.js";
import { buildRecommendAdjustmentsRouter } from "./routes/recommendAdjustments.js";

const config = loadConfig();
const provider = config.provider === "claude" ? new ClaudeProvider(config) : new OpenAIProvider(config);

const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));

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

app.use((error: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  const message = error instanceof Error ? error.message : "Internal server error";
  res.status(500).json({ error: "Internal server error", message });
});

app.listen(config.port, () => {
  console.log(`MCP server listening on http://localhost:${config.port}`);
  console.log(`AI provider: ${provider.name}`);
});
