⸻

# 📄 DataRetentionPolicy.md

**Version:** 1.0.0

**Scope:** Supabase Data Lifecycle & Cleanup Automation

**Author:** [You]

**Last Updated:** 2025-11-05

⸻

## 🎯 Purpose

Rendio AI, kullanıcı verilerini gereksiz yere saklamamak ve depolama maliyetini azaltmak için "auto-cleanup" sistemini uygular.

Kullanıcı videoları, işlem logları ve geçici dosyalar belirli bir süre sonunda otomatik olarak silinir veya arşivlenir.

⸻

## 🧱 Data Retention Rules

| Table / Bucket | Data Type | Retention Period | Action |
|----------------|-----------|------------------|--------|
| public.video_jobs | Video job metadata (prompt, result URL, timestamps) | 7 days | Delete row |
| storage.videos | Generated video files (Supabase bucket) | 7 days | Delete file via scheduled job |
| storage.thumbnails | Video thumbnail images (Supabase bucket) | 7 days | Delete file via scheduled job |
| public.quota_log | Credit spending/purchase records | 30 days | Archive (keep for audits) |
| public.idempotency_log | Duplicate prevention records | 24 hours (auto) | Delete expired (expires_at < NOW()) |
| users | DeviceID, credits, flags | Permanent | Keep (never auto-delete) |

⸻

## 🕒 Automation

- **Scheduler:** Supabase Edge Function or external CRON job (GitHub Actions / Fly.io / Railway Cron).
- **Execution:** Runs every 24h at 03:00 UTC.
- **Steps:**

1. Query video_jobs where `created_at < NOW() - INTERVAL '7 days'`.
2. Delete associated video files and thumbnails from Supabase Storage (`storage.remove`).
3. Delete expired idempotency records where `expires_at < NOW()`.
4. Send Telegram summary (see MonitoringAndAlerts.md).

⸻

## 🧩 Example Pseudocode

```typescript
// Supabase Edge Function (TypeScript)
// File: /supabase/functions/cleanup-old-data/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  // 1. Get expired video jobs (older than 7 days)
  const { data: expiredJobs } = await supabaseClient
    .from('video_jobs')
    .select('job_id, video_url, thumbnail_url')
    .lt('created_at', new Date(Date.now() - 7 * 24 * 3600 * 1000).toISOString())

  let deletedCount = 0

  // 2. Delete video files from storage
  for (const job of expiredJobs || []) {
    if (job.video_url) {
      const videoPath = new URL(job.video_url).pathname
      await supabaseClient.storage.from('videos').remove([videoPath])
    }
    if (job.thumbnail_url) {
      const thumbPath = new URL(job.thumbnail_url).pathname
      await supabaseClient.storage.from('thumbnails').remove([thumbPath])
    }

    // 3. Delete job record
    await supabaseClient
      .from('video_jobs')
      .delete()
      .eq('job_id', job.job_id)

    deletedCount++
  }

  // 4. Delete expired idempotency records (older than 24 hours)
  const { data: expiredIdempotency } = await supabaseClient
    .from('idempotency_log')
    .delete()
    .lt('expires_at', new Date().toISOString())
    .select()

  // 5. Send Telegram notification
  const message = `🧹 Cleanup completed:\n- ${deletedCount} old videos deleted\n- ${expiredIdempotency?.length || 0} idempotency records cleaned`
  await notifyTelegram(message)

  return new Response(JSON.stringify({ success: true, deletedCount }))
})
```

**Note:** Correct table names are `video_jobs` and `quota_log`, not `history` and `credits_log`.

**Reference:** See `backend-building-plan.md` Phase 0 for complete schema definition.

⸻

## 🔐 Security

- Cron job runs with Service Role Key (full access).
- Client cannot trigger cleanup manually.
- Logs of deletions are not public; they are sent only to admin Telegram channel.

⸻

## ✅ Summary

All generated videos and history entries older than 7 days are automatically deleted.

This ensures Rendio AI remains lightweight, compliant, and cost-efficient.

⸻
