import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { loadConfig } from "../config.js";

const originalEnv = process.env;

beforeEach(() => {
  process.env = { ...originalEnv };
  delete process.env.OPENAI_API_KEY;
  delete process.env.ANTHROPIC_API_KEY;
  delete process.env.AI_PROVIDER;
  delete process.env.PORT;
  delete process.env.MOCK_SCENARIO;
});

afterAll(() => {
  process.env = originalEnv;
});

describe("loadConfig", () => {
  it("loads mock provider without API keys", () => {
    process.env.AI_PROVIDER = "mock";
    const config = loadConfig();
    expect(config.provider).toBe("mock");
    expect(config.mockScenario).toBe("balanced");
  });

  it("requires OPENAI_API_KEY when provider is openai", () => {
    process.env.AI_PROVIDER = "openai";
    expect(() => loadConfig()).toThrow("OPENAI_API_KEY is required");
  });

  it("requires ANTHROPIC_API_KEY when provider is claude", () => {
    process.env.AI_PROVIDER = "claude";
    expect(() => loadConfig()).toThrow("ANTHROPIC_API_KEY is required");
  });

  it("accepts openai provider with key", () => {
    process.env.AI_PROVIDER = "openai";
    process.env.OPENAI_API_KEY = "test-key";
    const config = loadConfig();
    expect(config.provider).toBe("openai");
  });

  it("validates mock scenario values", () => {
    process.env.AI_PROVIDER = "mock";
    process.env.MOCK_SCENARIO = "not-valid";
    expect(() => loadConfig()).toThrow("Invalid MOCK_SCENARIO");
  });
});
