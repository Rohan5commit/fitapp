import { AppConfig } from "../config.js";
import { AIProvider, CompletionInput, composeUserPrompt, parseModelJson } from "./provider.js";

interface OpenAIChatResponse {
  choices?: Array<{
    message?: {
      content?: string;
    };
  }>;
}

export class OpenAIProvider implements AIProvider {
  readonly name = "openai";

  constructor(private readonly config: AppConfig) {}

  async completeJSON<T>(input: CompletionInput): Promise<T> {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${this.config.openAiApiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: this.config.openAiModel,
        temperature: 0.2,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: input.systemPrompt },
          { role: "user", content: composeUserPrompt(input.userPrompt, input.schemaHint) }
        ]
      })
    });

    const bodyText = await response.text();
    if (!response.ok) {
      throw new Error(`OpenAI API error ${response.status}: ${bodyText}`);
    }

    const data = JSON.parse(bodyText) as OpenAIChatResponse;
    const content = data.choices?.[0]?.message?.content;
    if (!content) {
      throw new Error("OpenAI response did not include message content.");
    }

    return parseModelJson(content) as T;
  }
}
