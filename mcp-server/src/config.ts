export type AIProviderName = "openai" | "claude";

export interface AppConfig {
  port: number;
  provider: AIProviderName;
  openAiApiKey?: string;
  openAiModel: string;
  anthropicApiKey?: string;
  anthropicModel: string;
}

function requireValue(value: string | undefined, message: string): string {
  if (!value || value.trim().length === 0) {
    throw new Error(message);
  }
  return value.trim();
}

export function loadConfig(): AppConfig {
  const provider = (process.env.AI_PROVIDER ?? "openai").trim().toLowerCase() as AIProviderName;
  if (provider !== "openai" && provider !== "claude") {
    throw new Error(`Invalid AI_PROVIDER: ${provider}`);
  }

  const port = Number.parseInt(process.env.PORT ?? "8787", 10);
  if (Number.isNaN(port) || port < 1 || port > 65535) {
    throw new Error(`Invalid PORT: ${process.env.PORT}`);
  }

  const config: AppConfig = {
    port,
    provider,
    openAiApiKey: process.env.OPENAI_API_KEY,
    openAiModel: process.env.OPENAI_MODEL ?? "gpt-4o",
    anthropicApiKey: process.env.ANTHROPIC_API_KEY,
    anthropicModel: process.env.ANTHROPIC_MODEL ?? "claude-3-5-sonnet-20241022"
  };

  if (provider === "openai") {
    config.openAiApiKey = requireValue(config.openAiApiKey, "OPENAI_API_KEY is required when AI_PROVIDER=openai");
  } else {
    config.anthropicApiKey = requireValue(config.anthropicApiKey, "ANTHROPIC_API_KEY is required when AI_PROVIDER=claude");
  }

  return config;
}
