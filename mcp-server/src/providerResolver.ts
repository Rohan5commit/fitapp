import { Request } from "express";
import { createProvider } from "./ai/providerFactory.js";
import { AIProvider } from "./ai/provider.js";
import { AIProviderName, AppConfig, MockScenario } from "./config.js";

const HEADER_PROVIDER = "x-fitmind-provider";
const HEADER_OPENAI_KEY = "x-fitmind-openai-key";
const HEADER_ANTHROPIC_KEY = "x-fitmind-anthropic-key";
const HEADER_MOCK_SCENARIO = "x-fitmind-mock-scenario";

function normalizeProvider(value: string | undefined): AIProviderName | undefined {
  const provider = value?.trim().toLowerCase();
  if (provider === "openai" || provider === "claude" || provider === "mock") {
    return provider;
  }
  return undefined;
}

function normalizeScenario(value: string | undefined): MockScenario | undefined {
  const scenario = value?.trim().toLowerCase();
  if (scenario === "balanced" || scenario === "recovery" || scenario === "performance") {
    return scenario;
  }
  return undefined;
}

function readHeaderValue(req: Request, name: string): string | undefined {
  const value = req.header(name);
  if (!value) {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function buildOverrideConfig(baseConfig: AppConfig, req: Request): AppConfig | undefined {
  const provider = normalizeProvider(readHeaderValue(req, HEADER_PROVIDER));
  const openAiApiKey = readHeaderValue(req, HEADER_OPENAI_KEY);
  const anthropicApiKey = readHeaderValue(req, HEADER_ANTHROPIC_KEY);
  const mockScenario = normalizeScenario(readHeaderValue(req, HEADER_MOCK_SCENARIO));

  const hasOverride =
    provider !== undefined ||
    openAiApiKey !== undefined ||
    anthropicApiKey !== undefined ||
    mockScenario !== undefined;

  if (!hasOverride) {
    return undefined;
  }

  const nextProvider = provider ?? baseConfig.provider;
  return {
    ...baseConfig,
    provider: nextProvider,
    openAiApiKey: openAiApiKey ?? baseConfig.openAiApiKey,
    anthropicApiKey: anthropicApiKey ?? baseConfig.anthropicApiKey,
    mockScenario: mockScenario ?? baseConfig.mockScenario
  };
}

export interface ProviderResolver {
  resolve(req: Request): AIProvider;
  defaultProvider: AIProvider;
}

export function createProviderResolver(baseConfig: AppConfig): ProviderResolver {
  const defaultProvider = createProvider(baseConfig);

  return {
    defaultProvider,
    resolve(req: Request): AIProvider {
      const overrideConfig = buildOverrideConfig(baseConfig, req);
      if (!overrideConfig) {
        return defaultProvider;
      }
      return createProvider(overrideConfig);
    }
  };
}
