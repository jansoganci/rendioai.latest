/**
 * Device Check Endpoint
 * 
 * Purpose: Guest user onboarding with DeviceCheck verification
 * 
 * Endpoint: POST /device-check
 * 
 * Request Body:
 * {
 *   "device_id": "uuid-string",
 *   "device_token": "base64-encoded-device-check-token"
 * }
 * 
 * Response:
 * {
 *   "user_id": "uuid",
 *   "credits_remaining": 10,
 *   "is_new": true
 * }
 * 
 * Note: For Phase 1, DeviceCheck verification is simplified (mock).
 * Real DeviceCheck verification will be implemented in Phase 0.5.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'

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

    const { device_id, device_token } = await req.json()

    // Validate input
    if (!device_id || !device_token) {
      return new Response(
        JSON.stringify({ error: 'device_id and device_token are required' }),
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

    // 1. Verify device token with Apple (simplified for MVP)
    // TODO (Phase 0.5): Implement full Apple DeviceCheck verification
    // See: https://developer.apple.com/documentation/devicecheck
    // For now, we'll do a basic validation
    if (!device_token || device_token.length < 10) {
      return new Response(
        JSON.stringify({ error: 'Invalid device token' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    logEvent('device_check_request', { device_id }, 'info')

    // 2. Check if user already exists
    const { data: existingUser, error: queryError } = await supabaseClient
      .from('users')
      .select('*')
      .eq('device_id', device_id)
      .single()

    if (queryError && queryError.code !== 'PGRST116') { // PGRST116 = no rows returned
      logEvent('device_check_error', { error: queryError.message }, 'error')
      throw queryError
    }

    // 3. Return existing user if found
    if (existingUser) {
      logEvent('device_check_existing_user', { 
        user_id: existingUser.id,
        device_id 
      }, 'info')

      return new Response(
        JSON.stringify({
          user_id: existingUser.id,
          credits_remaining: existingUser.credits_remaining,
          is_new: false
        }),
        { 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 4. Create new guest user (start with 0 credits)
    // Credits will be added via stored procedure to ensure proper audit trail
    const { data: newUser, error: insertError } = await supabaseClient
      .from('users')
      .insert({
        device_id: device_id,
        is_guest: true,
        tier: 'free',
        credits_remaining: 0,  // Start with 0, stored procedure will add 10
        credits_total: 0,       // Start with 0, stored procedure will update
        initial_grant_claimed: true,
        language: 'en',
        theme_preference: 'system'
      })
      .select()
      .single()

    if (insertError) {
      logEvent('device_check_insert_error', { 
        error: insertError.message,
        device_id 
      }, 'error')
      throw insertError
    }

    // 5. Grant initial credits using stored procedure
    // This ensures proper audit trail and atomic operation
    const { data: creditResult, error: creditError } = await supabaseClient.rpc('add_credits', {
      p_user_id: newUser.id,
      p_amount: 10,
      p_reason: 'initial_grant',
      p_transaction_id: null
    })

    if (creditError || !creditResult?.success) {
      logEvent('device_check_credit_error', { 
        error: creditError?.message || creditResult?.error,
        user_id: newUser.id 
      }, 'error')
      // Don't fail the request if credit logging fails, but log it
      console.error('Failed to grant initial credits:', creditError || creditResult?.error)
      // Return user with 0 credits if grant failed
      return new Response(
        JSON.stringify({
          user_id: newUser.id,
          credits_remaining: 0,
          is_new: true,
          warning: 'Initial credit grant failed'
        }),
        { 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    logEvent('device_check_new_user', { 
      user_id: newUser.id,
      device_id,
      credits_granted: 10,
      credits_remaining: creditResult.credits_remaining
    }, 'info')

    // 6. Return new user data with updated credits
    return new Response(
      JSON.stringify({
        user_id: newUser.id,
        credits_remaining: creditResult.credits_remaining,
        is_new: true
      }),
      { 
        headers: { 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    logEvent('device_check_unexpected_error', { 
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

