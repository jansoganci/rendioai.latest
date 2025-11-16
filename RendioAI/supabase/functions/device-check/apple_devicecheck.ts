/**
 * Apple DeviceCheck API Integration
 *
 * Handles JWT generation and API calls to Apple DeviceCheck service.
 *
 * Required Secrets (set via Supabase):
 * - APPLE_TEAM_ID: Your 10-character Apple Developer Team ID
 * - APPLE_KEY_ID: DeviceCheck key identifier from Apple Developer portal
 * - APPLE_DEVICECHECK_KEY_P8: Private key content (PEM format)
 * - APP_ENV: "production" or "sandbox" (optional, defaults to production)
 */

// Apple DeviceCheck endpoints
const APPLE_DEVICECHECK_ENDPOINTS = {
  production: 'https://api.devicecheck.apple.com',
  sandbox: 'https://api.development.devicecheck.apple.com'
}

const APPLE_TIMEOUT_MS = 5000
const JWT_VALIDITY_MINUTES = 20

/**
 * Generate Apple DeviceCheck JWT for authentication
 *
 * Algorithm: ES256 (ECDSA with SHA-256)
 * Validity: 20 minutes (recommended by Apple)
 *
 * @returns JWT string
 */
export async function createAppleJWT(): Promise<string> {
  const teamId = Deno.env.get('APPLE_TEAM_ID')
  const keyId = Deno.env.get('APPLE_KEY_ID')
  const privateKeyPEM = Deno.env.get('APPLE_DEVICECHECK_KEY_P8')

  if (!teamId || !keyId || !privateKeyPEM) {
    throw new Error('Missing Apple DeviceCheck credentials. Check APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_DEVICECHECK_KEY_P8 secrets.')
  }

  const now = Math.floor(Date.now() / 1000)
  const exp = now + (JWT_VALIDITY_MINUTES * 60)

  // JWT Header
  const header = {
    alg: 'ES256',
    kid: keyId,
    typ: 'JWT'
  }

  // JWT Payload
  const payload = {
    iss: teamId,
    iat: now,
    exp: exp
  }

  // Encode header and payload
  const encodedHeader = base64UrlEncode(JSON.stringify(header))
  const encodedPayload = base64UrlEncode(JSON.stringify(payload))
  const message = `${encodedHeader}.${encodedPayload}`

  // Sign with ES256
  const signature = await signES256(message, privateKeyPEM)
  const encodedSignature = base64UrlEncode(signature)

  return `${message}.${encodedSignature}`
}

/**
 * Query two bits from Apple DeviceCheck API
 *
 * @param deviceToken Base64-encoded device token from iOS
 * @param transactionId Unique transaction identifier (for idempotency)
 * @returns Apple DeviceCheck response with bit0, bit1, last_update_time
 */
export async function queryDeviceCheckBits(
  deviceToken: string,
  transactionId: string
): Promise<{
  bit0: number
  bit1: number
  last_update_time?: string
}> {
  const appEnv = Deno.env.get('APP_ENV') || 'production'
  const baseURL = APPLE_DEVICECHECK_ENDPOINTS[appEnv as keyof typeof APPLE_DEVICECHECK_ENDPOINTS]
    || APPLE_DEVICECHECK_ENDPOINTS.production

  const jwt = await createAppleJWT()

  const url = `${baseURL}/v1/query_two_bits`
  const body = {
    device_token: deviceToken,
    transaction_id: transactionId,
    timestamp: Date.now()
  }

  // DO NOT log device_token, JWT, or private key
  console.log(`📡 Querying Apple DeviceCheck API (env: ${appEnv})`)

  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), APPLE_TIMEOUT_MS)

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${jwt}`
      },
      body: JSON.stringify(body),
      signal: controller.signal
    })

    clearTimeout(timeoutId)

    // Read response body first
    const responseText = await response.text()

    if (!response.ok) {
      // Special case: "Failed to find bit state" means device is new (never queried before)
      // This is normal for first-time devices - treat as success with default bits
      if (responseText.includes('Failed to find bit state')) {
        console.log(`📝 Device has no bit state yet (first query) - using defaults (0, 0)`)
        return {
          bit0: 0,
          bit1: 0,
          last_update_time: new Date().toISOString()
        }
      }

      console.error(`❌ Apple DeviceCheck API error: HTTP ${response.status}`)
      console.error(`Response: ${responseText}`)
      throw new Error(`Apple DeviceCheck API error: ${response.status} - ${responseText}`)
    }

    // Parse JSON from response text
    let data
    try {
      data = JSON.parse(responseText)
    } catch (parseError) {
      console.error(`❌ Failed to parse Apple response as JSON: ${responseText}`)
      throw new Error(`Apple returned non-JSON response: ${responseText}`)
    }

    console.log(`✅ Apple DeviceCheck query succeeded (bit0: ${data.bit0}, bit1: ${data.bit1})`)

    return {
      bit0: data.bit0 || 0,
      bit1: data.bit1 || 0,
      last_update_time: data.last_update_time
    }

  } catch (error) {
    clearTimeout(timeoutId)

    if (error.name === 'AbortError') {
      throw new Error(`Apple DeviceCheck API timeout after ${APPLE_TIMEOUT_MS}ms`)
    }

    throw error
  }
}

/**
 * Update two.  bits on Apple DeviceCheck API (optional - for future use)
 *
 * @param deviceToken Base64-encoded device token from iOS
 * @param transactionId Unique transaction identifier
 * @param bit0 New value for bit 0 (0 or 1)
 * @param bit1 New value for bit 1 (0 or 1)
 */
export async function updateDeviceCheckBits(
  deviceToken: string,
  transactionId: string,
  bit0: number,
  bit1: number
): Promise<void> {
  const appEnv = Deno.env.get('APP_ENV') || 'production'
  const baseURL = APPLE_DEVICECHECK_ENDPOINTS[appEnv as keyof typeof APPLE_DEVICECHECK_ENDPOINTS]
    || APPLE_DEVICECHECK_ENDPOINTS.production

  const jwt = await createAppleJWT()

  const url = `${baseURL}/v1/update_two_bits`
  const body = {
    device_token: deviceToken,
    transaction_id: transactionId,
    timestamp: Date.now(),
    bit0: bit0,
    bit1: bit1
  }

  console.log(`📡 Updating Apple DeviceCheck bits (env: ${appEnv})`)

  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), APPLE_TIMEOUT_MS)

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${jwt}`
      },
      body: JSON.stringify(body),
      signal: controller.signal
    })

    clearTimeout(timeoutId)

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`Apple DeviceCheck API error: ${response.status} - ${errorText}`)
    }

    console.log(`✅ Apple DeviceCheck bits updated successfully`)

  } catch (error) {
    clearTimeout(timeoutId)

    if (error.name === 'AbortError') {
      throw new Error(`Apple DeviceCheck API timeout after ${APPLE_TIMEOUT_MS}ms`)
    }

    throw error
  }
}

// ============================================
// Crypto Helpers
// ============================================

/**
 * Base64 URL encode (without padding)
 */
function base64UrlEncode(data: string | ArrayBuffer): string {
  let base64: string

  if (typeof data === 'string') {
    base64 = btoa(data)
  } else {
    const bytes = new Uint8Array(data)
    const binary = Array.from(bytes).map(b => String.fromCharCode(b)).join('')
    base64 = btoa(binary)
  }

  return base64
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

/**
 * Sign message with ES256 (ECDSA with SHA-256)
 *
 * @param message Message to sign
 * @param privateKeyPEM Private key in PEM format
 * @returns Signature as ArrayBuffer
 */
async function signES256(message: string, privateKeyPEM: string): Promise<ArrayBuffer> {
  // Remove PEM headers/footers and whitespace
  const pemContents = privateKeyPEM
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')

  // Decode base64 to ArrayBuffer
  const binaryString = atob(pemContents)
  const bytes = new Uint8Array(binaryString.length)
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }

  // Import private key
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    bytes.buffer,
    {
      name: 'ECDSA',
      namedCurve: 'P-256'
    },
    false,
    ['sign']
  )

  // Sign the messagedx
  const encoder = new TextEncoder()
  const messageData = encoder.encode(message)

  const signature = await crypto.subtle.sign(
    {
      name: 'ECDSA',
      hash: 'SHA-256'
    },
    privateKey,
    messageData
  )

  return signature
}
