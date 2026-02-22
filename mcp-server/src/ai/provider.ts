export interface CompletionInput {
  systemPrompt: string;
  userPrompt: string;
  schemaHint: string;
}

export interface AIProvider {
  readonly name: string;
  completeJSON<T>(input: CompletionInput): Promise<T>;
}

export function parseModelJson(raw: string): unknown {
  const stripped = raw
    .trim()
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/\s*```$/i, "")
    .trim();

  return JSON.parse(stripped);
}

export function composeUserPrompt(userPrompt: string, schemaHint: string): string {
  return [
    userPrompt,
    "",
    "Return only valid JSON. Do not include markdown.",
    "Schema requirements:",
    schemaHint
  ].join("\n");
}
