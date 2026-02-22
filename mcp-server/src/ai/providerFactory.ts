import { AppConfig } from "../config.js";
import { ClaudeProvider } from "./claudeProvider.js";
import { MockProvider } from "./mockProvider.js";
import { OpenAIProvider } from "./openaiProvider.js";
import { AIProvider } from "./provider.js";

export function createProvider(config: AppConfig): AIProvider {
  switch (config.provider) {
    case "openai":
      return new OpenAIProvider(config);
    case "claude":
      return new ClaudeProvider(config);
    case "mock":
      return new MockProvider(config);
    default: {
      const exhaustive: never = config.provider;
      throw new Error(`Unsupported provider: ${exhaustive}`);
    }
  }
}
