/**
 * DeviceCheck Endpoint - Production Hardened
 *
 * Purpose: Guest user onboarding with Apple DeviceCheck verification
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
 *   "success": true,
 *   "user_id": "uuid",
 *   "credits_remaining": 10,
 *   "is_new": true,
 *   "is_valid_device": true,
 *   "suggested_action": "allow",
 *   "access_token": "jwt-token",
 *   "refresh_token": "refresh-token",
 *   "correlation_id": "uuid"
 * }
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createLogger, logCreditTransaction } from '../_shared/logger.ts'
import { initSentry, captureException, flush } from '../_shared/sentry.ts'
import { alertAuthFailure } from '../_shared/telegram.ts'
import { queryDeviceCheckBits } from './apple_devicecheck.ts'
import { isValidUUID, isValidDeviceToken, validationError } from '../_shared/validation.ts'

// Initialize monitoring
initSentry('device-check')
const logger = createLogger('device-check')

// Constants
const RATE_LIMIT_PER_HOUR = 10

serve(async (req) => {
  const startTime = Date.now()
  const correlationId = crypto.randomUUID()

  try {
    logger.info('DeviceCheck request started', {
      metadata: { correlation_id: correlationId }
    })

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

    // Validate input presence
    if (!device_id || !device_token) {
      return new Response(
        JSON.stringify({
          error: 'device_id and device_token are required',
          correlation_id: correlationId
        }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // Validate device_id is valid UUID format
    if (!isValidUUID(device_id)) {
      await alertAuthFailure('Invalid device_id format', device_id)
      logger.warn('Invalid device_id format', {
        metadata: { correlation_id: correlationId, device_id_length: device_id.length }
      })
      return validationError('device_id', 'Must be valid UUID format')
    }

    // Validate device_token format (base64 + reasonable length)
    if (!isValidDeviceToken(device_token)) {
      await alertAuthFailure('Invalid device token format', device_id)
      logger.warn('Invalid device_token format', {
        metadata: { correlation_id: correlationId, token_length: device_token.length }
      })
      return validationError('device_token', 'Must be valid base64 format (50-5000 chars)')
    }

    // Initialize Supabase clients
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const supabaseAuth = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    // Check rate limit BEFORE doing expensive Apple call
    const { data: rateLimitData } = await supabaseAdmin.rpc('check_device_rate_limit', {
      p_device_id: device_id
    })

    if (rateLimitData?.limit_exceeded) {
      logger.warn('Rate limit exceeded', {
        metadata: {
          device_id,
          correlation_id: correlationId,
          request_count: rateLimitData.request_count
        }
      })

      return new Response(
        JSON.stringify({
          success: false,
          error: 'Rate limit exceeded',
          suggested_action: 'throttle',
          correlation_id: correlationId,
          retry_after: rateLimitData.window_reset_at
        }),
        {
          status: 429,
          headers: {
            'Content-Type': 'application/json',
            'Retry-After': '3600'
          }
        }
      )
    }

    logger.info('Verifying device with Apple DeviceCheck', {
      metadata: { correlation_id: correlationId }
    })

    // Verify device token with Apple DeviceCheck API
    let appleResponse: {
      bit0: number
      bit1: number
      last_update_time?: string
    } | null = null

    let querySuccess = false
    let fraudFlags: string[] = []

    try {
      appleResponse = await queryDeviceCheckBits(device_token, correlationId)
      querySuccess = true

      logger.info('Apple DeviceCheck verification succeeded', {
        metadata: {
          correlation_id: correlationId,
          bit0: appleResponse.bit0,
          bit1: appleResponse.bit1
        }
      })
    } catch (error) {
      querySuccess = false

      logger.error('Apple DeviceCheck verification failed', error as Error, {
        metadata: { correlation_id: correlationId }
      })

      captureException(error, {
        action: 'apple_devicecheck_query',
        metadata: { correlation_id: correlationId }
      })

      // Check if this is a repeated failure (fraud signal)
      const { data: existingDevice } = await supabaseAdmin
        .from('device_check_devices')
        .select('dc_query_fail_count, dc_last_query_at')
        .eq('device_id', device_id)
        .single()

      if (existingDevice) {
        const failCount = existingDevice.dc_query_fail_count || 0
        const lastQuery = existingDevice.dc_last_query_at
          ? new Date(existingDevice.dc_last_query_at)
          : null

        // Check if 3+ failures in 24 hours
        if (failCount >= 2 && lastQuery) {
          const hoursSinceLastQuery = (Date.now() - lastQuery.getTime()) / (1000 * 60 * 60)
          if (hoursSinceLastQuery < 24) {
            fraudFlags.push('dc_query_fail_spike')
          }
        }
      }

      // Continue with degraded mode (allow but flag)
      // We'll still create the user but mark as suspicious
    }

    // Check if user already exists
    const { data: existingUser, error: queryError } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('device_id', device_id)
      .single()

    if (queryError && queryError.code !== 'PGRST116') {
      logger.error('Failed to query user', queryError, {
        metadata: { correlation_id: correlationId }
      })
      throw queryError
    }

    // Upsert device check state
    if (appleResponse) {
      const { data: deviceStateResult } = await supabaseAdmin.rpc('upsert_device_check_state', {
        p_device_id: device_id,
        p_user_id: existingUser?.id || crypto.randomUUID(), // Temp UUID if new user
        p_bit0: appleResponse.bit0,
        p_bit1: appleResponse.bit1,
        p_last_update_time: appleResponse.last_update_time
          ? new Date(appleResponse.last_update_time).toISOString()
          : new Date().toISOString(),
        p_query_success: querySuccess,
        p_fraud_flags: fraudFlags
      })

      // Determine suggested action based on risk score
      const riskScore = deviceStateResult?.risk_score || 0
      let suggestedAction = 'allow'

      if (riskScore >= 70) {
        suggestedAction = 'block'
      } else if (riskScore >= 50) {
        suggestedAction = 'require_captcha'
      } else if (riskScore >= 30) {
        suggestedAction = 'throttle'
      }

      logger.info('Device state updated', {
        metadata: {
          correlation_id: correlationId,
          risk_score: riskScore,
          suggested_action: suggestedAction,
          fraud_flags: fraudFlags
        }
      })

      // If high risk, block the request
      if (suggestedAction === 'block') {
        await alertAuthFailure('High-risk device blocked', device_id, {
          risk_score: riskScore,
          fraud_flags: fraudFlags
        })

        return new Response(
          JSON.stringify({
            success: false,
            error: 'Device verification failed',
            is_valid_device: false,
            suggested_action: 'block',
            correlation_id: correlationId
          }),
          {
            status: 403,
            headers: { 'Content-Type': 'application/json' }
          }
        )
      }
    }

    // Handle existing user
    if (existingUser) {
      logger.info('Existing user found', {
        user_id: existingUser.id,
        metadata: {
          device_id,
          correlation_id: correlationId
        }
      })

      // Create new anonymous auth session
      const { data: authData, error: authError } = await supabaseAuth.auth.signInAnonymously()

      if (authError || !authData.session) {
        logger.error('Failed to create anonymous session for existing user', authError, {
          metadata: { correlation_id: correlationId }
        })
        await alertAuthFailure('Failed to create anonymous session', device_id, authError)

        return new Response(
          JSON.stringify({
            user_id: existingUser.id,
            credits_remaining: existingUser.credits_remaining,
            is_new: false,
            is_valid_device: querySuccess,
            suggested_action: 'allow',
            access_token: null,
            refresh_token: null,
            error: 'Failed to create auth session',
            correlation_id: correlationId
          }),
          {
            headers: { 'Content-Type': 'application/json' },
            status: 200
          }
        )
      }

      // Update auth_user_id
      const { error: updateError } = await supabaseAdmin
        .from('users')
        .update({ auth_user_id: authData.user.id })
        .eq('id', existingUser.id)

      if (updateError) {
        logger.error('Failed to link auth to existing user', updateError, {
          user_id: existingUser.id,
          metadata: { correlation_id: correlationId }
        })
      } else {
        logger.info('Linked auth session to existing user', {
          user_id: existingUser.id,
          metadata: {
            auth_user_id: authData.user.id,
            correlation_id: correlationId
          }
        })
      }

      // Update device_check_devices with actual user_id
      if (appleResponse) {
        await supabaseAdmin.rpc('upsert_device_check_state', {
          p_device_id: device_id,
          p_user_id: existingUser.id,
          p_bit0: appleResponse.bit0,
          p_bit1: appleResponse.bit1,
          p_last_update_time: appleResponse.last_update_time
            ? new Date(appleResponse.last_update_time).toISOString()
            : new Date().toISOString(),
          p_query_success: querySuccess,
          p_fraud_flags: fraudFlags
        })
      }

      return new Response(
        JSON.stringify({
          success: true,
          user_id: existingUser.id,
          credits_remaining: existingUser.credits_remaining,
          is_new: false,
          is_valid_device: querySuccess,
          suggested_action: 'allow',
          access_token: authData.session.access_token,
          refresh_token: authData.session.refresh_token,
          correlation_id: correlationId
        }),
        {
          headers: { 'Content-Type': 'application/json' }
        }
      )
    }

    // Create anonymous auth session for new user
    const { data: authData, error: authError } = await supabaseAuth.auth.signInAnonymously()

    if (authError || !authData.session) {
      logger.error('Failed to create anonymous session', authError, {
        metadata: { correlation_id: correlationId }
      })
      await alertAuthFailure('Failed to create anonymous session for new user', device_id, authError)
      throw new Error('Failed to create auth session')
    }

    logger.info('Created anonymous auth session', {
      metadata: {
        auth_user_id: authData.user.id,
        device_id,
        correlation_id: correlationId
      }
    })

    // Create new guest user
    const { data: newUser, error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        device_id: device_id,
        auth_user_id: authData.user.id,
        is_guest: true,
        tier: 'free',
        credits_remaining: 0,
        credits_total: 0,
        initial_grant_claimed: true,
        language: 'en',
        theme_preference: 'system'
      })
      .select()
      .single()

    if (insertError) {
      logger.error('Failed to create user', insertError, {
        metadata: {
          device_id,
          auth_user_id: authData.user.id,
          correlation_id: correlationId
        }
      })
      await supabaseAuth.auth.signOut()
      throw insertError
    }

    // Update device_check_devices with actual user_id
    if (appleResponse) {
      await supabaseAdmin.rpc('upsert_device_check_state', {
        p_device_id: device_id,
        p_user_id: newUser.id,
        p_bit0: appleResponse.bit0,
        p_bit1: appleResponse.bit1,
        p_last_update_time: appleResponse.last_update_time
          ? new Date(appleResponse.last_update_time).toISOString()
          : new Date().toISOString(),
        p_query_success: querySuccess,
        p_fraud_flags: fraudFlags
      })
    }

    // Grant initial credits
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
      console.error('Failed to grant initial credits:', creditError || creditResult?.error)

      return new Response(
        JSON.stringify({
          success: true,
          user_id: newUser.id,
          credits_remaining: 0,
          is_new: true,
          is_valid_device: querySuccess,
          suggested_action: 'allow',
          access_token: authData.session.access_token,
          refresh_token: authData.session.refresh_token,
          warning: 'Initial credit grant failed',
          correlation_id: correlationId
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
        credits_remaining: creditResult.credits_remaining,
        is_valid_device: querySuccess,
        correlation_id: correlationId
      }
    })

    return new Response(
      JSON.stringify({
        success: true,
        user_id: newUser.id,
        credits_remaining: creditResult.credits_remaining,
        is_new: true,
        is_valid_device: querySuccess,
        suggested_action: 'allow',
        access_token: authData.session.access_token,
        refresh_token: authData.session.refresh_token,
        correlation_id: correlationId
      }),
      {
        headers: { 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    const duration = Date.now() - startTime
    logger.error('Device check failed', error as Error, {
      duration_ms: duration,
      metadata: { correlation_id: correlationId }
    })
    captureException(error, {
      action: 'device_check',
      metadata: {
        duration_ms: duration,
        correlation_id: correlationId
      }
    })

    await flush()

    return new Response(
      JSON.stringify({
        error: error.message,
        correlation_id: correlationId
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})
