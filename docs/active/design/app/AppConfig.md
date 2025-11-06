⸻

# ⚙️ App Configuration — RendioAI

**App Name:** RendioAI

**Version:** 1.0.0

**Author:** [You]

**Last Updated:** 2025-11-05

⸻

## 🌐 API Configuration

| Key | Value | Description |
|-----|-------|-------------|
| API_BASE_URL | https://xyz.supabase.co/functions/v1 | Supabase Edge Function base endpoint |
| FAL_API_URL | https://fal.ai/api | FalAI base endpoint (used in backend) |

⸻

## 💰 Credit System

| Key | Value | Description |
|-----|-------|-------------|
| DEFAULT_CREDITS | 10 | Number of free credits for new users |
| CREDIT_SOURCE | Supabase.app_settings | Stored in database, editable anytime |
| CREDIT_POLICY | Static per app version; updated via Supabase setting | |

**Note:**

- The value of DEFAULT_CREDITS is fetched from Supabase table `app_settings`.
- To update, change the row in Supabase — no code update required.

⸻

## 🎬 Fal Model Configuration

| Key | Value | Description |
|-----|-------|-------------|
| DEFAULT_MODEL_ID | fal-ai/veo3.1 | Primary text-to-video model |
| PROVIDER | FalAI | AI service provider |
| DEFAULT_SETTINGS | `{ "aspect_ratio": "16:9", "duration": "8s", "resolution": "720p", "generate_audio": true }` | Default generation parameters |

⸻

## 🧩 App Behavior

| Key | Value | Description |
|-----|-------|-------------|
| DEFAULT_LANGUAGE | en | App language |
| DEFAULT_THEME | system | Light/Dark behavior |
| ENABLE_DEVICE_CHECK | true | Guest security verification |
| ENABLE_IAP | true | Enable in-app purchases |
| SHOW_TUTORIAL_ON_FIRST_LAUNCH | true | Onboarding tutorial toggle |

⸻

## 🔒 Environment Variables (Backend)

| Variable | Description |
|----------|-------------|
| SUPABASE_URL | Backend URL |
| SUPABASE_ANON_KEY | Public API key |
| FAL_KEY | FalAI API key (server-side only) |
| APPLE_TEAM_ID | For DeviceCheck integration |
| IAP_PRODUCT_IDS | App Store product identifiers |

⸻

## 🧠 Notes

- All configuration values are read at launch and cached in memory.
- Supabase table `app_settings` allows dynamic updates (no rebuild needed).
- Backend API uses DEFAULT_MODEL_ID to route generation requests.

⸻

**End of Document**

AppConfig.md defines all default constants, API paths, and behavior flags for RendioAI version 1.0.0.

⸻
