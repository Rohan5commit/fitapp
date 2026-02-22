import "dotenv/config";
import { createProvider } from "./ai/providerFactory.js";
import { createApp } from "./app.js";
import { loadConfig } from "./config.js";

const config = loadConfig();
const provider = createProvider(config);
const app = createApp(provider);

app.listen(config.port, () => {
  console.log(`MCP server listening on http://localhost:${config.port}`);
  console.log(`AI provider: ${provider.name}`);
  if (provider.name === "mock") {
    console.log(`Mock scenario: ${config.mockScenario}`);
  }
});
