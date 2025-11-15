/**
 * Device Check Endpoint
 *
 * Purpose: Guest user onboarding with DeviceCheck verification and anonymous auth
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
 *   "is_new": true,
 *   "access_token": "jwt-token",  // NEW: For Storage operations
 *   "refresh_token": "refresh-token"  // NEW: To refresh session
 * }
 *
 * Note: For Phase 1, DeviceCheck verification is simplified (mock).
 * Real DeviceCheck verification will be implemented in Phase 0.5.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createLogger, logCreditTransaction } from '../_shared/logger.ts'
import { initSentry, captureException, flush } from '../_shared/sentry.ts'
import { alertAuthFailure } from '../_shared/telegram.ts'

// Initialize monitoring
initSentry('device-check')
const logger = createLogger('device-check')

serve(async (req) => {
  const startTime = Date.now()

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

    // Initialize Supabase clients
    // Service role client for database operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Anon client for auth operations
    const supabaseAuth = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    // 1. Verify device token with Apple (simplified for MVP)
    // TODO (Phase 0.5): Implement full Apple DeviceCheck verification
    // See: https://developer.apple.com/documentation/devicecheck
    // For now, we'll do a basic validation
    if (!device_token || device_token.length < 10) {
      await alertAuthFailure('Invalid device token', device_id)
      return new Response(
        JSON.stringify({ error: 'Invalid device token' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    logger.info('Device check request', { user_id: device_id })

    // 2. Check if user already exists
    const { data: existingUser, error: queryError } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('device_id', device_id)
      .single()

    if (queryError && queryError.code !== 'PGRST116') { // PGRST116 = no rows returned
      logger.error('Failed to query user', queryError, { user_id: device_id })
      throw queryError
    }

    // 3. Handle existing user
    if (existingUser) {
      logger.info('Existing user found', {
        user_id: existingUser.id,
        metadata: { device_id }
      })

      // Always create new anonymous auth session for existing users
      // This ensures we always return valid tokens for Storage operations
      // Note: Supabase anonymous auth cannot reuse existing sessions,
      // so we create a new session each time
      const { data: authData, error: authError } = await supabaseAuth.auth.signInAnonymously()

      if (authError || !authData.session) {
        logger.error('Failed to create anonymous session for existing user', authError)
        await alertAuthFailure('Failed to create anonymous session', device_id, authError)
        
        // Return response without tokens (graceful degradation)
        // App can still function, but image uploads will fail
        return new Response(
          JSON.stringify({
            user_id: existingUser.id,
            credits_remaining: existingUser.credits_remaining,
            is_new: false,
            access_token: null,
            refresh_token: null,
            error: 'Failed to create auth session'
          }),
          {
            headers: { 'Content-Type': 'application/json' },
            status: 200  // Still return 200, but with null tokens
          }
        )
      }

      // Update auth_user_id (even if it already exists)
      // This links the user to the new auth session
      const { error: updateError } = await supabaseAdmin
        .from('users')
        .update({ auth_user_id: authData.user.id })
        .eq('id', existingUser.id)

      if (updateError) {
        logger.error('Failed to link auth to existing user', updateError, {
          user_id: existingUser.id
        })
        // Continue anyway - tokens are still valid even if update fails
      } else {
        logger.info('Linked auth session to existing user', {
          user_id: existingUser.id,
          metadata: { auth_user_id: authData.user.id }
        })
      }

      return new Response(
        JSON.stringify({
          user_id: existingUser.id,
          credits_remaining: existingUser.credits_remaining,
          is_new: false,
          access_token: authData.session.access_token,  // ✅ Always returns token
          refresh_token: authData.session.refresh_token  // ✅ Always returns token
        }),
        {
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // 4. Create anonymous auth session FIRST for new user
    const { data: authData, error: authError } = await supabaseAuth.auth.signInAnonymously()

    if (authError || !authData.session) {
      logger.error('Failed to create anonymous session', authError)
      await alertAuthFailure('Failed to create anonymous session for new user', device_id, authError)
      throw new Error('Failed to create auth session')
    }

    logger.info('Created anonymous auth session', {
      metadata: { auth_user_id: authData.user.id, device_id }
    })

    // 5. Create new guest user linked to auth session
    // Credits will be added via stored procedure to ensure proper audit trail
    const { data: newUser, error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        device_id: device_id,
        auth_user_id: authData.user.id,  // Link to Supabase auth
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
      logger.error('Failed to create user', insertError, {
        user_id: device_id,
        metadata: { auth_user_id: authData.user.id }
      })
      // Clean up auth session if user creation fails
      await supabaseAuth.auth.signOut()
      throw insertError
    }

    // 6. Grant initial credits using stored procedure
    // This ensures proper audit trail and atomic operation
    const { data: creditResult, error: creditError } = await supabaseAdmin.rpc('add_credits', {
      p_user_id: newUser.id,
      p_amount: 10,
      p_reason: 'initial_grant',
      p_transaction_id: null
    })

    if (creditError || !creditResult?.success) {
      logCreditTransaction(
        logger,
        newUser.id,
        'add',
        10,
        false,
        undefined,
        creditError?.message || creditResult?.error
      )
      // Don't fail the request if credit logging fails, but log it
      console.error('Failed to grant initial credits:', creditError || creditResult?.error)
      // Return user with 0 credits if grant failed
      return new Response(
        JSON.stringify({
          user_id: newUser.id,
          credits_remaining: 0,
          is_new: true,
          access_token: authData.session.access_token,
          refresh_token: authData.session.refresh_token,
          warning: 'Initial credit grant failed'
        }),
        {
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    logCreditTransaction(
      logger,
      newUser.id,
      'add',
      10,
      true,
      creditResult.credits_remaining
    )

    logger.info('New user created with initial credits', {
      user_id: newUser.id,
      metadata: {
        device_id,
        auth_user_id: authData.user.id,
        credits_granted: 10,
        credits_remaining: creditResult.credits_remaining
      }
    })

    // 7. Return new user data with auth tokens
    return new Response(
      JSON.stringify({
        user_id: newUser.id,
        credits_remaining: creditResult.credits_remaining,
        is_new: true,
        access_token: authData.session.access_token,
        refresh_token: authData.session.refresh_token
      }),
      {
        headers: { 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    const duration = Date.now() - startTime
    logger.error('Device check failed', error as Error, {
      duration_ms: duration
    })
    captureException(error, {
      action: 'device_check',
      metadata: { duration_ms: duration }
    })

    await flush()  // Ensure logs are sent before function ends

    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})

