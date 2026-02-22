import "dotenv/config";
import { createApp } from "./app.js";
import { loadConfig } from "./config.js";
import { createProviderResolver } from "./providerResolver.js";

const config = loadConfig();
const providerResolver = createProviderResolver(config);
const app = createApp(providerResolver);

app.listen(config.port, () => {
  console.log(`MCP server listening on http://localhost:${config.port}`);
  console.log(`AI provider: ${providerResolver.defaultProvider.name}`);
  if (providerResolver.defaultProvider.name === "mock") {
    console.log(`Mock scenario: ${config.mockScenario}`);
  }
});
