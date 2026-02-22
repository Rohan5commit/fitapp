# FitMind

AI-powered fitness coaching app for macOS 14+ and watchOS 10+, backed by a local MCP server that can call OpenAI or Anthropic.

## Screenshots

![macOS Dashboard](docs/screenshots/macos-dashboard.png)
![watchOS Active Workout](docs/screenshots/watch-active-workout.png)

Screenshot placeholders are included; add real captures under `docs/screenshots/`.

## Architecture

High-level architecture and data flow are in `docs/architecture.md`.

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
│   │   ├── index.ts
│   │   ├── routes/
│   │   └── ai/
│   ├── .env.example
│   └── package.json
├── docs/
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
4. Install dependencies and run in dev mode.

   ```bash
   npm install
   npm run dev
   ```

The server exposes:
- `POST /analyze-trends`
- `POST /generate-plan`
- `POST /recommend-adjustments`

## App Setup (Xcode)

1. Open `FitApp-macOS/FitApp_macOS.xcodeproj` in Xcode.
2. Add the watch target (`FitApp-watchOS`) if not already mapped in your local project settings.
3. Enable capabilities:
   - HealthKit (macOS + watchOS)
   - Watch Connectivity
   - Sign in with Apple (if enabled in target)
4. Run macOS app target first, then watchOS target.

## Key App Features

- Onboarding with profile + goals + preferences.
- AI weekly plan generation via MCP server.
- Trend analysis and adjustment recommendations.
- HealthKit + WatchConnectivity service scaffolding.
- SwiftData model graph for profile, plans, and logs.

## Environment Variables (`mcp-server/.env`)

```
PORT=8787
AI_PROVIDER=openai

OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o

ANTHROPIC_API_KEY=
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
```

## License

MIT (`LICENSE`)
