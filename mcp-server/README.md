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

## Commands

```bash
npm install
npm run dev
npm run typecheck
npm test
npm run build
```

## API Contract

- OpenAPI schema: `../docs/openapi.yaml`
- Example payloads: `../docs/api.md`
