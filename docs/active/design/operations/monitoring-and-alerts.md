⸻

# 📄 MonitoringAndAlerts.md

**Version:** 1.0.0

**Scope:** Real-time Operational Notifications via Telegram

**Author:** [You]

**Last Updated:** 2025-11-05

⸻

## 🎯 Purpose

Provide real-time awareness of critical events (new users, credit purchases, video generation stats, cleanup results) directly in a private Telegram channel.

⸻

## 🔧 Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| TELEGRAM_BOT_TOKEN | Telegram bot API token | 1234567890:ABCdefGhijKlmNoPQRstuVWxyz |
| TELEGRAM_CHAT_ID | Admin or group chat ID | -1001234567890 |
| ALERT_WEBHOOK_URL | Optional proxy endpoint | https://api.rendioai.com/alerts |

All credentials are stored as environment variables — never committed to Git.

⸻

## 📬 Events

| Event | Trigger | Message Format |
|-------|---------|----------------|
| New User Created | DeviceCheck grants first credits | 👋 New user joined: deviceID=abcd1234 |
| Credit Purchase | User buys credits | 💰 Credit purchase: +50 credits (user_id=xyz) |
| Video Generation | Job completed successfully | 🎥 Video generated: 720p / 8s / user_id=xyz |
| Cleanup Summary | Cron job finished | 🧹 Cleanup completed: 124 history rows deleted |
| Error Alert | Function failure | 🚨 Error: Fal API timeout (job_id=abc) |

⸻

## ⚙️ Example Swift Logic

```swift
func notifyTelegram(_ message: String) async {
    guard let token = Env.get("TELEGRAM_BOT_TOKEN"),
          let chat = Env.get("TELEGRAM_CHAT_ID") else { return }
    
    let url = URL(string: "https://api.telegram.org/bot\(token)/sendMessage")!
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.httpBody = "chat_id=\(chat)&text=\(message)"
        .data(using: .utf8)
    
    _ = try? await URLSession.shared.data(for: req)
}
```

⸻

## 🔐 Security & Privacy

- Messages contain no personal data — only anonymized IDs or device hashes.
- Telegram logs are for operational awareness only (no analytics).
- Bot token stored server-side, never in the iOS app.

⸻

## ✅ Summary

This alert system gives immediate visibility of key actions:

- New users joining
- Credit purchases
- Cron cleanup results
- API or processing errors

Together with DataRetentionPolicy.md, it keeps Rendio AI clean, observable, and secure.

⸻
