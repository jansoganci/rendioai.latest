⸻

# 🔐 Security Policies — Rendio AI

**Version:** 1.0.0

**Scope:** Supabase RLS + Client Access + Privacy Rules

**Author:** [You]

**Last Updated:** 2025-11-05

⸻

## 🧭 1. Access Layers

| Access Type | Description | Example Features |
|-------------|-------------|------------------|
| Anonymous | App yükleyen ama login olmayan kullanıcı. | İlk kredi (Default 10), video oluşturma, geçmiş kaydı. |
| Authenticated (Apple Sign-in) | Kayıtlı kullanıcı. Kalıcı krediler, satın alma erişimi, profil. | Satın alma, geçmişe tam erişim. |
| Admin | Sadece internal yönetim. Supabase panel erişimi. | Model fiyatları, kullanıcı bakiyesi, istatistikler. |

⸻

## 🧱 2. Row-Level Security (RLS)

### Enabled Tables

| Table | Rule Summary | Example Policy |
|-------|--------------|----------------|
| users | Her kullanıcı yalnızca kendi satırını görebilir. | `auth.uid() = id` |
| history | Kullanıcı sadece kendi video geçmişini görür. | `auth.uid() = user_id` |
| credits_log | Kullanıcı yalnızca kendi kredi işlemlerini görebilir. | `auth.uid() = user_id` |
| models | Herkese açık. RLS devre dışı. | `SELECT * FROM models;` |

⸻

### RLS Ruleset Example

```sql
-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Allow select/update only for self
CREATE POLICY "Users can access own data" 
ON public.users
FOR SELECT USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- History table
CREATE POLICY "View own history"
ON public.history
FOR SELECT USING (auth.uid() = user_id);
```

⸻

## 🗝️ 3. API Key & Client Security

| Component | Rule | Reason |
|-----------|------|--------|
| FAL_KEY | Yalnızca backend içinde (Supabase Edge Function) saklanır. | iOS uygulaması istemci tarafında key tutamaz. |
| Supabase anon key | Salt okuma izinli. Yazma işlemleri Edge Functions aracılığıyla yapılır. | RLS bypass engeli. |
| Server functions | Her hassas işlem (kredi düşürme, video kaydı, ilk grant) sadece Edge Function içinde yapılır. | Veri bütünlüğü. |

⸻

## 👤 4. User Data Privacy

| Data Type | Storage | Access Scope | Notes |
|-----------|---------|--------------|-------|
| credits_remaining | Supabase users table | Private | Sadece kendi hesabı görüntüler. |
| device_id | Local + Server | Private | DeviceCheck ile doğrulanır. |
| video_url | Supabase Storage (private bucket) | Private + Download link | Paylaşım linki expiring URL ile oluşturulur. |
| models metadata | Public models table | Public | Tüm kullanıcılar görebilir. |

⸻

## 🧩 5. Data Flow Security Notes

### 1. DeviceCheck Integration

- App açılışında backend token doğrular.
- İlk defa girişte `initial_grant_claimed = false` ise kredi verir, sonra `true` yapar.

### 2. Free Credit Banner

- Görüldüğünde `UserDefaults.hasSeenWelcomeBanner = true`.
- Backend'de `initial_grant_claimed = true`.
- Böylece kullanıcı tekrar kredi alamaz.

### 3. Video Generation

- Fal API istekleri yalnızca backend üzerinden yapılır.
- iOS istemcisi prompt + ayarları gönderir; key asla uygulamada saklanmaz.

### 4. Download & Share

- Videolar Supabase private bucket'ta saklanır.
- Paylaşım linkleri süreli (signed URL) olarak üretilir.

⸻

## ✅ 6. Security Compliance Summary

| Layer | Status |
|-------|--------|
| RLS Policies | ✅ Active |
| Edge Function Enforcement | ✅ In Progress |
| Anonymous Access Isolation | ✅ Configured |
| DeviceCheck Verification | ✅ Planned |
| GDPR/Privacy Ready | ✅ No personal data collected |

⸻

**End of Document**

Bu doküman MVP'nin tüm güvenlik çerçevesini belirler.

Supabase'te migration yapılırken bu kurallar doğrudan RLS politikalarına dönüştürülür.

⸻
