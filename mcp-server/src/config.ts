export type AIProviderName = "openai" | "claude" | "mock";
export type MockScenario = "balanced" | "recovery" | "performance";

export interface AppConfig {
  port: number;
  provider: AIProviderName;
  openAiApiKey?: string;
  openAiModel: string;
  anthropicApiKey?: string;
  anthropicModel: string;
  mockScenario: MockScenario;
  nodeEnv: string;
}

function requireValue(value: string | undefined, message: string): string {
  if (!value || value.trim().length === 0) {
    throw new Error(message);
  }
  return value.trim();
}

function parseProvider(value: string | undefined): AIProviderName {
  const provider = (value ?? "openai").trim().toLowerCase();
  if (provider === "openai" || provider === "claude" || provider === "mock") {
    return provider;
  }
  throw new Error(`Invalid AI_PROVIDER: ${provider}`);
}

function parseMockScenario(value: string | undefined): MockScenario {
  const scenario = (value ?? "balanced").trim().toLowerCase();
  if (scenario === "balanced" || scenario === "recovery" || scenario === "performance") {
    return scenario;
  }
  throw new Error(`Invalid MOCK_SCENARIO: ${scenario}`);
}

export function loadConfig(): AppConfig {
  const provider = parseProvider(process.env.AI_PROVIDER);

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
    anthropicModel: process.env.ANTHROPIC_MODEL ?? "claude-3-5-sonnet-20241022",
    mockScenario: parseMockScenario(process.env.MOCK_SCENARIO),
    nodeEnv: process.env.NODE_ENV ?? "development"
  };

  if (provider === "openai") {
    config.openAiApiKey = requireValue(config.openAiApiKey, "OPENAI_API_KEY is required when AI_PROVIDER=openai");
  }

  if (provider === "claude") {
    config.anthropicApiKey = requireValue(config.anthropicApiKey, "ANTHROPIC_API_KEY is required when AI_PROVIDER=claude");
  }

  return config;
}
