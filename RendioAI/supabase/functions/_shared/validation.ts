/**
 * Input Validation Utilities
 *
 * Provides validation functions for common input types to prevent:
 * - Malformed data
 * - DoS attacks (huge strings)
 * - Data corruption
 */

// UUID format: 8-4-4-4-12 hexadecimal characters
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

// Base64 format (standard and URL-safe)
// Padding (=) only allowed at the end, max 2 chars
const BASE64_REGEX = /^[A-Za-z0-9+/\-_]*={0,2}$/

// Apple Subject ID format (sub.xxxx...)
const APPLE_SUB_REGEX = /^[a-zA-Z0-9._-]+$/

/**
 * Validate UUID format
 */
export function isValidUUID(value: string): boolean {
  if (!value || typeof value !== 'string') {
    return false
  }
  return UUID_REGEX.test(value)
}

/**
 * Validate base64 string
 */
export function isValidBase64(value: string): boolean {
  if (!value || typeof value !== 'string') {
    return false
  }
  return BASE64_REGEX.test(value)
}

/**
 * Validate Apple Subject ID
 */
export function isValidAppleSub(value: string): boolean {
  if (!value || typeof value !== 'string') {
    return false
  }
  // Apple subs are typically 30-100 chars
  if (value.length < 10 || value.length > 200) {
    return false
  }
  return APPLE_SUB_REGEX.test(value)
}

/**
 * Validate string length
 */
export function isValidLength(value: string, min: number, max: number): boolean {
  if (!value || typeof value !== 'string') {
    return false
  }
  return value.length >= min && value.length <= max
}

/**
 * Sanitize string to prevent XSS/injection
 * Removes any potentially dangerous characters
 */
export function sanitizeString(value: string): string {
  if (!value || typeof value !== 'string') {
    return ''
  }
  // Remove null bytes, control characters, and normalize whitespace
  return value
    .replace(/\0/g, '')
    .replace(/[\x00-\x1F\x7F]/g, '')
    .trim()
}

/**
 * Validate device token format (base64 + length check)
 */
export function isValidDeviceToken(token: string): boolean {
  if (!token || typeof token !== 'string') {
    return false
  }

  // Must be reasonable length (Apple tokens are typically 100-3000 chars)
  if (token.length < 50 || token.length > 5000) {
    return false
  }

  // Must be base64 format
  return isValidBase64(token)
}

/**
 * Validation error response builder
 */
export function validationError(field: string, reason: string): Response {
  return new Response(
    JSON.stringify({
      error: 'Validation failed',
      field: field,
      reason: reason
    }),
    {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    }
  )
}
