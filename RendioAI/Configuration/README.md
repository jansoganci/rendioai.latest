# ⚙️ Configuration Files

This folder contains environment-specific build configuration files (`.xcconfig`).

## Files

- **`Development.xcconfig`** - Development environment settings
- **`Staging.xcconfig`** - Staging environment settings  
- **`Production.xcconfig`** - Production environment settings

## Setup

See: `docs/active/backend/implementation/CONFIGURATION_SETUP.md`

## Usage

These files are linked to Xcode build configurations. Values are accessed via `AppConfig.swift`:

```swift
let url = AppConfig.supabaseURL
let key = AppConfig.supabaseAnonKey
```

## Security

⚠️ **Production keys:** Update `Production.xcconfig` with real production values before deploying.

