# MCP Server

Local middleware for AI workout generation and trend analysis.

## Endpoints

- `POST /analyze-trends`
- `POST /generate-plan`
- `POST /recommend-adjustments`
- `GET /health`

## Providers

Set `AI_PROVIDER` in `.env`:

- `openai` (requires `OPENAI_API_KEY`)
- `claude` (requires `ANTHROPIC_API_KEY`)
- `mock` (no API key required, useful for local UI testing)

`MOCK_SCENARIO` options:

- `balanced`
- `recovery`
- `performance`

### Optional per-request provider override headers

The macOS app can override provider and API keys per request without changing `.env`.

- `x-fitmind-provider`: `openai` | `claude` | `mock`
- `x-fitmind-openai-key`: OpenAI API key for this request
- `x-fitmind-anthropic-key`: Anthropic API key for this request
- `x-fitmind-mock-scenario`: `balanced` | `recovery` | `performance`

If no override headers are supplied, the server uses `.env` defaults.

## Commands

Node version is pinned via `.nvmrc` (`20`).

```bash
npm install
npm run dev
npm run typecheck
npm test
npm run build
```

Smoke test while server is running:

```bash
./scripts/smoke_test.sh
```

## API Contract

- OpenAPI schema: `../docs/openapi.yaml`
- Example payloads: `../docs/api.md`
