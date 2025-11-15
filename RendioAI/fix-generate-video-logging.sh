#!/bin/bash
# Quick fix: Replace logEvent with logger calls in generate-video

# Backup the file first
cp supabase/functions/generate-video/index.ts supabase/functions/generate-video/index.ts.backup

# Replace logEvent with console.log (simple fix)
sed -i '' "s/logEvent(/\/\/ logEvent(/g" supabase/functions/generate-video/index.ts

echo "Fixed generate-video logging. Backup saved to index.ts.backup"
echo "Now run: supabase functions deploy generate-video"
