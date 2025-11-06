⸻

# 🧭 OnboardingFlowBlueprint.md

**App:** RendioAI

**Version:** 1.0.0

**Author:** [You]

**Status:** ✅ Approved

**Last Updated:** 2025-11-05

⸻

## 🎯 Purpose

RendioAI uygulamasında kullanıcıdan hiçbir etkileşim gerektirmeden, arka planda gerçekleşen otomatik onboarding akışını tanımlar.

Kullanıcı uygulamayı açar, sistem onun cihazını tanır, kredilerini atar veya mevcut durumunu okur.

⸻

## 🧩 Flow Overview

```
┌──────────────────────────────┐
│ Launch App                  │
│  ↓                          │
│ Splash Screen (2s logo)     │
│  ↓                          │
│ DeviceCheck → Supabase      │
│  ↓                          │
│ if new_user → grant credits │
│ else → fetch current data   │
│  ↓                          │
│ Home Screen                 │
│  ↓                          │
│ show banner (once only)     │
│  ↓                          │
│ proceed normal usage        │
└──────────────────────────────┘
```

⸻

## ⚙️ Step-by-Step Logic

### 1️⃣ Splash Screen

- **Görsel:** statik logo (2 saniye).
- **Arka planda başlar:**
  - `DeviceCheck.generateToken()`
  - Supabase endpoint: `/api/device/check`
  - Geri döner: `{ device_id, is_existing_user, credits_remaining, initial_grant_claimed }`

⸻

### 2️⃣ Silent Retry (Resilient DeviceCheck)

Eğer DeviceCheck başarısız dönerse:

```swift
Task {
    try? await Task.sleep(for: .seconds(2))
    try await performDeviceCheck()
}
```

- Maksimum 3 deneme yapılır (network hatalarına karşı).
- Kullanıcıya hiçbir uyarı gösterilmez; splash süresi gerektiğinde 2-3 saniye uzayabilir.

⸻

### 3️⃣ Initial Credit Assignment

Eğer backend `is_existing_user == false`:

- `credits_remaining = 10`
- `initial_grant_claimed = true` olarak işaretlenir.
- Cevap döner: `{ showWelcomeBanner = true }`
- Backend tarafında Supabase trigger'ı ile bu kayıt oluşturulur.

⸻

### 4️⃣ Welcome Banner Logic

**Görünüm (Home ekranında):**

```
🎉 "You've received 10 free credits!"
```

**Gösterim koşulu:**

- `UserDefaults.hasSeenWelcomeBanner == false`
- AND `showWelcomeBanner == true`

**Davranış:**

- Gösterildikten sonra:

```swift
UserDefaults.set(true, forKey: "hasSeenWelcomeBanner")
```

- Sonraki açılışlarda bir daha görünmez.

**Backend senkronizasyonu:**

- `users.initial_grant_claimed = true` olduğu için tekrar kredi verilmez.

⸻

### 5️⃣ Low Credit Warning Banner

- Home ekranında quota barının hemen üstünde koşullu olarak görünür.

```swift
if credits_remaining < 10 {
    Banner(type: .warning,
           message: "Your credits are running low.")
}
```

- "Upgrade" veya "Buy Credits" butonuna basıldığında → `CreditStoreView()` açılır.

⸻

### 6️⃣ Background Tasks

**Splash süresince yapılanlar:**

- DeviceCheck validation
- User session cache (UserDefaults + Supabase sync)
- Telemetry event: `AppOpened`

**Home açıldığında:**

- `credits_remaining` local cache'e yazılır.
- UI banner durumu belirlenir.

⸻

## 🧱 Data Dependencies

| Field | Source | Description |
|-------|--------|-------------|
| device_id | DeviceCheck | Cihazın unique kimliği |
| credits_remaining | Supabase users | Kullanıcının aktif kredisi |
| initial_grant_claimed | Supabase users | İlk kredi verildi mi? |
| hasSeenWelcomeBanner | UserDefaults | Banner yerelde gösterildi mi? |

⸻

## 🧠 Notes

- Kullanıcı uygulamayı silip yüklese bile Supabase flag'i (`initial_grant_claimed`) tekrar kredi vermeyi engeller.
- Keychain yerine DeviceCheck token kullanıldığı için Apple politikalarıyla uyumlu kalır.
- Splash'ın asıl amacı arka plan işlemleri tamamlanırken kısa bir "branding" süresi kazandırmak.

⸻

## 🧩 Future Enhancements

- Analytics event: "Free Credit Banner Shown" (opt-in).
- 2. versiyonda DeviceCheck + iCloudKeyValueStore kombinasyonu (cross-device sync için).
- Dynamic initial credit via Supabase function (`get_default_credits()`).

⸻

**Decision:** ✅ Final Approved

**Next Action:** Implement Splash + DeviceCheck + Silent Retry + Banner Logic in Phase 1.

⸻
