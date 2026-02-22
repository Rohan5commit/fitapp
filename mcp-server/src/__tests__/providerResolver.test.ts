import { Request } from "express";
import { describe, expect, it } from "vitest";
import { AppConfig } from "../config.js";
import { createProviderResolver } from "../providerResolver.js";

function makeRequest(headers: Record<string, string>): Request {
  const normalized: Record<string, string> = {};
  for (const [key, value] of Object.entries(headers)) {
    normalized[key.toLowerCase()] = value;
  }

  return {
    header(name: string): string | undefined {
      return normalized[name.toLowerCase()];
    }
  } as Request;
}

const baseConfig: AppConfig = {
  port: 8787,
  provider: "mock",
  openAiModel: "gpt-4o",
  anthropicModel: "claude-3-5-sonnet-20241022",
  mockScenario: "balanced",
  nodeEnv: "test"
};

describe("provider resolver", () => {
  it("returns default provider when no override headers are provided", () => {
    const resolver = createProviderResolver(baseConfig);
    const provider = resolver.resolve(makeRequest({}));

    expect(provider).toBe(resolver.defaultProvider);
    expect(provider.name).toBe("mock");
  });

  it("supports provider override to openai with request key", () => {
    const resolver = createProviderResolver(baseConfig);
    const provider = resolver.resolve(
      makeRequest({
        "x-fitmind-provider": "openai",
        "x-fitmind-openai-key": "sk-test"
      })
    );

    expect(provider).not.toBe(resolver.defaultProvider);
    expect(provider.name).toBe("openai");
  });

  it("supports provider override to claude with request key", () => {
    const resolver = createProviderResolver(baseConfig);
    const provider = resolver.resolve(
      makeRequest({
        "x-fitmind-provider": "claude",
        "x-fitmind-anthropic-key": "claude-test"
      })
    );

    expect(provider).not.toBe(resolver.defaultProvider);
    expect(provider.name).toBe("claude");
  });

  it("keeps default provider when override is invalid", () => {
    const resolver = createProviderResolver(baseConfig);
    const provider = resolver.resolve(
      makeRequest({
        "x-fitmind-provider": "invalid-provider"
      })
    );

    expect(provider).toBe(resolver.defaultProvider);
    expect(provider.name).toBe("mock");
  });
});
