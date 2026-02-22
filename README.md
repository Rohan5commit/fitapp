# FitMind

AI-powered fitness coaching app for macOS 14+ and watchOS 10+, backed by a local MCP server that can call OpenAI, Anthropic Claude, or a deterministic mock provider.

## Project Status

- `mcp-server`: Implemented with all required endpoints, schema validation, provider switching, tests, and CI.
- `FitApp-macOS`: SwiftUI + SwiftData scaffold implemented for onboarding, dashboard, generator, insights, history, settings, offline fallback, and service layer.
- `FitApp-watchOS`: SwiftUI companion scaffold implemented for active workout flow, quick stats, local cache, and WatchConnectivity sync.
- `Xcode project`: source tree is ready; final target wiring/signing is done in Xcode on macOS.

## Screenshots

![macOS Dashboard](docs/screenshots/macos-dashboard.png)
![watchOS Active Workout](docs/screenshots/watch-active-workout.png)

Screenshot placeholders are included; add real captures under `docs/screenshots/`.

## Architecture and API

- High-level architecture: `docs/architecture.md`
- API payload examples: `docs/api.md`
- OpenAPI contract: `docs/openapi.yaml`

## Repo Layout

```
fitapp/
├── FitApp-macOS/
│   ├── Views/
│   ├── Models/
│   ├── Services/
│   └── FitApp_macOS.xcodeproj/
├── FitApp-watchOS/
│   ├── Views/
│   ├── Services/
│   └── Models/
├── mcp-server/
│   ├── src/
│   ├── .env.example
│   ├── package.json
│   └── README.md
├── docs/
├── .github/workflows/
├── LICENSE
├── README.md
└── .gitignore
```

## MCP Server Setup

1. Install Node 20+.
2. Copy env template.

   ```bash
   cd mcp-server
   cp .env.example .env
   ```

3. Configure provider + API key in `.env`.
4. Install dependencies and run:

   ```bash
   npm install
   npm run dev
   ```

Optional deterministic mode for UI development:

```
AI_PROVIDER=mock
MOCK_SCENARIO=balanced
```

The server exposes:
- `POST /analyze-trends`
- `POST /generate-plan`
- `POST /recommend-adjustments`
- `GET /health`

## App Setup (Xcode)

1. Open `FitApp-macOS/FitApp_macOS.xcodeproj` in Xcode.
2. Add the watch target (`FitApp-watchOS`) if not already mapped in your local project settings.
3. Enable capabilities:
   - HealthKit (macOS + watchOS)
   - Watch Connectivity
   - Sign in with Apple (optional, depending on your target config)
4. Run macOS app target first, then watchOS target.

## CI

GitHub Actions workflow:

- `.github/workflows/mcp-server-ci.yml`

It runs install, typecheck, tests, and build for `mcp-server` on push/PR.

## License

MIT (`LICENSE`)
