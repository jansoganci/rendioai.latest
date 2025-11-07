/**
 * Apple IAP Verifier
 * 
 * Handles Apple In-App Purchase verification and product configuration
 * 
 * Note: For Phase 1, verification is simplified (mock).
 * Real Apple App Store Server API verification will be implemented in Phase 0.5.
 */

export interface VerificationResult {
  valid: boolean
  product_id: string
}

/**
 * Product configuration mapping
 * NEVER trust client - always use server-side config
 */
export const PRODUCT_CONFIG: Record<string, number> = {
  'com.rendio.credits.10': 10,
  'com.rendio.credits.50': 50,
  'com.rendio.credits.100': 100
}

/**
 * Get credits amount for a product ID
 * 
 * @param productId - Apple product ID
 * @returns Credits amount or null if product not found
 */
export function getCreditsForProduct(productId: string): number | null {
  return PRODUCT_CONFIG[productId] || null
}

/**
 * Simplified Apple IAP verification (mock for Phase 1)
 * 
 * TODO (Phase 0.5): Implement real Apple App Store Server API verification
 * See: backend-building-plan.md Phase 0.5 for full implementation
 * 
 * In Phase 0.5, this will:
 * 1. Call Apple's App Store Server API v2
 * 2. Verify JWS (JSON Web Signature) response
 * 3. Check transaction status
 * 4. Extract product_id from verified response
 * 5. Handle subscription vs one-time purchase
 * 
 * @param transactionId - Apple transaction ID
 * @returns Verification result with product_id
 */
export async function verifyWithApple(transactionId: string): Promise<VerificationResult> {
  // For Phase 1, we'll do basic validation
  // In Phase 0.5, this will call Apple's App Store Server API v2
  
  if (!transactionId || transactionId.length < 10) {
    return {
      valid: false,
      product_id: ''
    }
  }

  // Mock validation - always succeeds for Phase 1
  // Extract product ID from transaction ID pattern (for testing)
  // In production, Apple API will return the actual product_id
  
  // For now, default to 10 credits package
  // In real implementation, we'd parse the JWS response from Apple
  return {
    valid: true,
    product_id: 'com.rendio.credits.10' // Mock product ID
  }
}

/**
 * Verify transaction and get credits amount
 * 
 * Convenience function that combines verification and product lookup
 * 
 * @param transactionId - Apple transaction ID
 * @returns Credits amount or null if invalid/unknown product
 */
export async function verifyAndGetCredits(transactionId: string): Promise<number | null> {
  const verification = await verifyWithApple(transactionId)
  
  if (!verification.valid) {
    return null
  }
  
  return getCreditsForProduct(verification.product_id)
}

