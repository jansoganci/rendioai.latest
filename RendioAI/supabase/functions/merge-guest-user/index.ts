/**
 * Merge Guest User Endpoint
 *
 * Purpose: Merge guest account with authenticated Apple user
 *
 * Endpoint: POST /merge-guest-user
 *
 * Request Body:
 * {
 *   "device_id": "device-uuid",
 *   "apple_sub": "apple-sub-id"
 * }
 *
 * Response:
 * {
 *   "success": true,
 *   "user": { User object with merged credits }
 * }
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'

serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const { device_id, apple_sub } = await req.json()

    if (!device_id || !apple_sub) {
      return new Response(JSON.stringify({ error: 'device_id and apple_sub required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    logEvent('merge_guest_user_request', { device_id, apple_sub }, 'info')

    // 1. Find guest user
    const { data: guestUser, error: guestError } = await supabase
      .from('users')
      .select('*')
      .eq('device_id', device_id)
      .eq('is_guest', true)
      .single()

    if (guestError || !guestUser) {
      logEvent('merge_guest_user_not_found', { device_id }, 'warn')
      return new Response(JSON.stringify({ error: 'Guest user not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // 2. Find or create Apple user
    let { data: appleUser } = await supabase
      .from('users')
      .select('*')
      .eq('apple_sub', apple_sub)
      .single()

    if (!appleUser) {
      // Create new Apple user
      logEvent('merge_guest_user_creating_apple_user', { apple_sub }, 'info')

      const { data: newUser, error: createError } = await supabase
        .from('users')
        .insert({
          apple_sub: apple_sub,
          is_guest: false,
          tier: 'free',
          credits_remaining: 0,
          credits_total: 0,
          language: guestUser.language || 'en',
          theme_preference: guestUser.theme_preference || 'system'
        })
        .select()
        .single()

      if (createError) {
        // Handle unique constraint violation (race condition)
        // This can happen if two merge requests for the same apple_sub execute concurrently
        if (createError.code === '23505') {
          // Another request created the user - fetch it
          logEvent('merge_guest_user_race_condition_handled', { apple_sub }, 'info')

          const { data: existingUser, error: fetchError } = await supabase
            .from('users')
            .select('*')
            .eq('apple_sub', apple_sub)
            .single()

          if (fetchError || !existingUser) {
            throw new Error('Failed to create or find Apple user after race condition')
          }

          appleUser = existingUser
        } else {
          throw createError
        }
      } else {
        appleUser = newUser
      }
    }

    // 3. Calculate total credits
    const totalCreditsRemaining = (guestUser.credits_remaining || 0) + (appleUser.credits_remaining || 0)
    const totalCreditsLifetime = (guestUser.credits_total || 0) + (appleUser.credits_total || 0)

    logEvent('merge_guest_user_transferring', {
      guest_credits: guestUser.credits_remaining,
      apple_credits: appleUser.credits_remaining,
      total_credits: totalCreditsRemaining
    }, 'info')

    // 4. Transfer video_jobs
    const { error: jobsError } = await supabase
      .from('video_jobs')
      .update({ user_id: appleUser.id })
      .eq('user_id', guestUser.id)

    if (jobsError) {
      logEvent('merge_guest_user_jobs_error', { error: jobsError.message }, 'warn')
      // Continue anyway - video history loss is acceptable for merge operation
      // Credits and account merge are more critical than preserving video history
    }

    // 5. Transfer quota_log
    const { error: quotaError } = await supabase
      .from('quota_log')
      .update({ user_id: appleUser.id })
      .eq('user_id', guestUser.id)

    if (quotaError) {
      logEvent('merge_guest_user_quota_error', { error: quotaError.message }, 'warn')
      // Continue anyway - quota log is for audit purposes only
      // The actual credits are transferred in step 6, which is critical
    }

    // 6. Update Apple user with merged credits
    const { data: mergedUser, error: updateError } = await supabase
      .from('users')
      .update({
        credits_remaining: totalCreditsRemaining,
        credits_total: totalCreditsLifetime,
        device_id: device_id, // Keep device_id
        updated_at: new Date().toISOString()
      })
      .eq('id', appleUser.id)
      .select()
      .single()

    if (updateError) {
      throw updateError
    }

    // 7. Delete guest user (CASCADE handles related data)
    const { error: deleteError } = await supabase
      .from('users')
      .delete()
      .eq('id', guestUser.id)

    if (deleteError) {
      logEvent('merge_guest_user_delete_error', { error: deleteError.message }, 'warn')
      // Continue anyway - merge succeeded
    }

    logEvent('merge_guest_user_success', {
      apple_user_id: appleUser.id,
      credits_merged: totalCreditsRemaining
    }, 'info')

    return new Response(JSON.stringify({
      success: true,
      user: mergedUser
    }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    logEvent('merge_guest_user_error', { error: error.message }, 'error')

    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
