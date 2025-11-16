# DeviceCheck Edge Function - Production Hardened

## Overview

This Edge Function verifies iOS device tokens with Apple's DeviceCheck API to prevent fraud and multi-account abuse.

## Required Secrets

Set these via Supabase Dashboard → Project Settings → Edge Functions → Secrets:

```bash
APPLE_TEAM_ID=ABC123DEFG           # Your 10-char Apple Team ID
APPLE_KEY_ID=WXYZ987654            # DeviceCheck key ID from Apple portal
APPLE_DEVICECHECK_KEY_P8=-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSMPOCRG...
-----END PRIVATE KEY-----          # Full PEM private key (ES256)

APP_ENV=production                 # or "sandbox" for testing (optional)
```

## How to Get Apple Credentials

1. **Apple Developer Portal** → https://developer.apple.com/account/resources/authkeys/list
2. **Click** "+" to create new key
3. **Name**: "DeviceCheck Production Key"
4. **Enable**: DeviceCheck checkbox
5. **Download** `.p8` file (you can only download once!)
6. **Note** the Key ID (e.g., `WXYZ987654`)
7. **Get Team ID** from top-right corner (e.g., `ABC123DEFG`)

## Deployment

### 1. Run Migration

```bash
cd /Users/jans./Downloads/RendioAI/RendioAI
supabase db push
```

This creates the `device_check_devices` table with fraud detection.

### 2. Set Secrets

```bash
# Using Supabase CLI
supabase secrets set APPLE_TEAM_ID=ABC123DEFG
supabase secrets set APPLE_KEY_ID=WXYZ987654
supabase secrets set APPLE_DEVICECHECK_KEY_P8="$(cat /path/to/AuthKey_WXYZ987654.p8)"
supabase secrets set APP_ENV=production
```

**OR** via Supabase Dashboard:
1. Go to **Project Settings** → **Edge Functions**
2. Scroll to **Secrets**
3. Add each secret

### 3. Deploy Function

```bash
supabase functions deploy device-check
```

### 4. Verify

Check logs:
```bash
supabase functions logs device-check --tail
```

## How It Works

```
iOS App
  ↓ Generates DeviceCheck token
  ↓ POST /device-check { device_id, device_token }
  ↓
Edge Function
  ↓ 1. Check rate limit (10/hour)
  ↓ 2. Verify token with Apple DeviceCheck API
  ↓ 3. Calculate risk score (0-100)
  ↓ 4. Store device state in database
  ↓ 5. Return { is_valid_device, suggested_action }
  ↓
iOS App receives response
```

## Fraud Detection

### Risk Signals

| Signal | Trigger | Risk Points |
|--------|---------|-------------|
| `dc_query_fail_spike` | 3+ Apple API failures in 24h | +20 |
| `multi_account_risk` | Same device_id with different user_ids | +30 |
| `bit_flapping_suspected` | Bits change < 24h apart | +15 |

### Suggested Actions

| Risk Score | Action | Behavior |
|------------|--------|----------|
| 0-29 | `allow` | Normal operation |
| 30-49 | `throttle` | Rate limit |
| 50-69 | `require_captcha` | Add friction |
| 70-100 | `block` | Deny access (HTTP 403) |

## Rate Limiting

- **Limit**: 10 requests per device per hour
- **Response**: HTTP 429 with `Retry-After: 3600`

## Testing

### Test with iOS Simulator

Run your iOS app and check the backend logs:

```bash
supabase functions logs device-check --tail
```

Look for:
- ✅ `Apple DeviceCheck verification succeeded`
- ✅ `Device state updated` with risk_score
- ✅ `correlation_id` in every log line

### Expected Response

```json
{
  "success": true,
  "user_id": "uuid",
  "credits_remaining": 10,
  "is_new": true,
  "is_valid_device": true,
  "suggested_action": "allow",
  "access_token": "jwt...",
  "refresh_token": "refresh...",
  "correlation_id": "uuid"
}
```

## Monitoring

### Key Metrics

Check in Supabase Database:

```sql
-- View device check stats
SELECT
  device_id,
  dc_query_success_count,
  dc_query_fail_count,
  risk_score,
  fraud_flags,
  created_at
FROM device_check_devices
ORDER BY created_at DESC
LIMIT 10;

-- High-risk devices
SELECT *
FROM device_check_devices
WHERE risk_score >= 50
ORDER BY risk_score DESC;

-- Rate limit hits
SELECT *
FROM device_check_devices
WHERE request_count_1h >= 10
AND request_window_start > NOW() - INTERVAL '1 hour';
```

### Logs

All logs include `correlation_id` for tracing:

```json
{
  "level": "info",
  "message": "Apple DeviceCheck verification succeeded",
  "metadata": {
    "correlation_id": "123e4567-e89b-12d3-a456-426614174000",
    "bit0": 0,
    "bit1": 1
  }
}
```

## Troubleshooting

### "Missing Apple DeviceCheck credentials"

**Fix**: Check secrets are set
```bash
supabase secrets list
```

Should show:
- `APPLE_TEAM_ID`
- `APPLE_KEY_ID`
- `APPLE_DEVICECHECK_KEY_P8`

### "Apple DeviceCheck API error: 401"

**Causes**:
- Wrong `APPLE_TEAM_ID` or `APPLE_KEY_ID`
- Private key format incorrect (must include `-----BEGIN PRIVATE KEY-----`)
- Key doesn't have DeviceCheck enabled in Apple portal

**Fix**: Re-download `.p8` file and verify secrets

### "Apple DeviceCheck API timeout"

**Cause**: Network timeout (default 5 seconds)

**Fix**: Check logs for actual error. Apple API might be down.

### Rate limit hit immediately

**Cause**: Testing too fast

**Fix**: Reset rate limit in database:
```sql
UPDATE device_check_devices
SET request_count_1h = 0,
    request_window_start = NOW()
WHERE device_id = 'YOUR_DEVICE_ID';
```

## Security

✅ Private key never logged
✅ Device tokens not logged
✅ JWT validity: 20 minutes
✅ Rate limiting per device
✅ RLS enforced on database
✅ Secrets in Supabase Vault

## Future Enhancements

1. **Bit Strategy**: Use `bit0` and `bit1` to track device state
2. **Update Bits**: Call `updateDeviceCheckBits()` to persist fraud signals
3. **Circuit Breaker**: Auto-disable Apple calls if API is down
4. **A/B Testing**: Vary risk thresholds

## References

- [Apple DeviceCheck Documentation](https://developer.apple.com/documentation/devicecheck)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
