/**
 * Update Credits Endpoint
 * 
 * Purpose: Process Apple In-App Purchases (credit packages)
 * 
 * Endpoint: POST /update-credits
 * 
 * Request Body:
 * {
 *   "user_id": "uuid",
 *   "transaction_id": "apple-transaction-id"
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "credits_added": 50,
 *   "credits_remaining": 60
 * }
 * 
 * Note: For Phase 1, Apple IAP verification is simplified (mock).
 * Real Apple App Store Server API verification will be implemented in Phase 0.5.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'
import { verifyWithApple, getCreditsForProduct } from '../_shared/apple-iap-verifier.ts'

serve(async (req) => {
  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { 
          status: 405, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    const { user_id, transaction_id } = await req.json()

    // Validate input
    if (!user_id || !transaction_id) {
      return new Response(
        JSON.stringify({ error: 'user_id and transaction_id are required' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // Initialize Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    logEvent('update_credits_request', { 
      user_id, 
      transaction_id 
    }, 'info')

    // 1. Verify transaction with Apple's App Store Server API
    const verification = await verifyWithApple(transaction_id)

    if (!verification.valid) {
      logEvent('update_credits_invalid_transaction', { 
        user_id, 
        transaction_id 
      }, 'warn')

      return new Response(
        JSON.stringify({ error: 'Invalid transaction' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 2. Get credits amount for product (NEVER trust client - always use server-side config)
    const creditsToAdd = getCreditsForProduct(verification.product_id)

    if (!creditsToAdd) {
      logEvent('update_credits_unknown_product', { 
        user_id, 
        product_id: verification.product_id 
      }, 'warn')

      return new Response(
        JSON.stringify({ error: 'Unknown product' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 3. Add credits atomically using stored procedure
    // The stored procedure handles duplicate transaction prevention
    const { data: result, error: rpcError } = await supabaseClient.rpc('add_credits', {
      p_user_id: user_id,
      p_amount: creditsToAdd,
      p_reason: 'iap_purchase',
      p_transaction_id: transaction_id
    })

    if (rpcError) {
      logEvent('update_credits_rpc_error', { 
        error: rpcError.message,
        user_id 
      }, 'error')
      throw rpcError
    }

    if (!result.success) {
      logEvent('update_credits_failed', { 
        error: result.error,
        user_id,
        transaction_id 
      }, 'warn')

      return new Response(
        JSON.stringify({ error: result.error }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    logEvent('update_credits_success', { 
      user_id,
      credits_added: creditsToAdd,
      credits_remaining: result.credits_remaining,
      transaction_id 
    }, 'info')

    // 4. Return success response
    return new Response(
      JSON.stringify({
        success: true,
        credits_added: creditsToAdd,
        credits_remaining: result.credits_remaining
      }),
      { 
        headers: { 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    logEvent('update_credits_unexpected_error', { 
      error: error.message,
      stack: error.stack 
    }, 'error')

    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
})

