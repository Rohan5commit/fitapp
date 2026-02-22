import { AppConfig } from "../config.js";
import { AIProvider, CompletionInput, composeUserPrompt, parseModelJson } from "./provider.js";

interface ClaudeMessageResponse {
  content?: Array<{ type?: string; text?: string }>;
}

export class ClaudeProvider implements AIProvider {
  readonly name = "claude";

  constructor(private readonly config: AppConfig) {}

  async completeJSON<T>(input: CompletionInput): Promise<T> {
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": String(this.config.anthropicApiKey),
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
      },
      body: JSON.stringify({
        model: this.config.anthropicModel,
        max_tokens: 1800,
        temperature: 0.2,
        system: input.systemPrompt,
        messages: [
          {
            role: "user",
            content: composeUserPrompt(input.userPrompt, input.schemaHint)
          }
        ]
      })
    });

    const bodyText = await response.text();
    if (!response.ok) {
      throw new Error(`Anthropic API error ${response.status}: ${bodyText}`);
    }

    const data = JSON.parse(bodyText) as ClaudeMessageResponse;
    const textBlock = data.content?.find((item) => item.type === "text")?.text;
    if (!textBlock) {
      throw new Error("Anthropic response did not include text content.");
    }

    return parseModelJson(textBlock) as T;
  }
}
