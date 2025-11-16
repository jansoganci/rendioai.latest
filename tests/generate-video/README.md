# 🧪 Generate Video Endpoint - Testing

This directory contains all testing files for the `generate-video` Edge Function.

## 📁 Files

- **`TESTING.md`** - Complete testing guide (read this first)
- **`test-endpoint.sh`** - Automated test script
- **`test.sh`** - Quick test script
- **`get-test-data.sh`** - Helper script to get test data
- **`get-test-data.sql`** - SQL queries

## 🚀 Quick Start

1. **Get test data:**
   ```sql
   -- Run in Supabase SQL Editor
   SELECT id, credits_remaining FROM users WHERE credits_remaining > 0 LIMIT 1;
   SELECT id, name FROM themes WHERE is_available = true LIMIT 1;
   ```

2. **Set environment variables:**
   ```bash
   export ANON_KEY="your_anon_key"
   export USER_ID="your_user_id"
   export THEME_ID="your_theme_id"
   ```

3. **Run tests:**
   ```bash
   cd tests/generate-video
   ./test-endpoint.sh
   ```

## 📖 Documentation

See **`TESTING.md`** for complete testing instructions, test cases, and troubleshooting.
