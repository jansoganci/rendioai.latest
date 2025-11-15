/**
 * Delete Account Endpoint
 *
 * Purpose: Delete user account and all associated data
 *
 * Endpoint: POST /delete-account
 *
 * Request Body:
 * {
 *   "user_id": "uuid"
 * }
 *
 * Response:
 * {
 *   "success": true
 * }
 *
 * Note: CASCADE deletion automatically handles:
 * - video_jobs (ON DELETE CASCADE)
 * - quota_log (ON DELETE CASCADE)
 * Storage cleanup can be added later if needed
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

    const { user_id } = await req.json()

    if (!user_id) {
      return new Response(JSON.stringify({ error: 'user_id required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    logEvent('delete_account_request', { user_id }, 'info')

    // Verify user exists before deletion
    const { data: user, error: fetchError } = await supabase
      .from('users')
      .select('id, email, is_guest')
      .eq('id', user_id)
      .single()

    if (fetchError || !user) {
      logEvent('delete_account_user_not_found', { user_id }, 'warn')
      return new Response(JSON.stringify({ error: 'User not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Delete user (CASCADE handles video_jobs, quota_log automatically)
    const { error: deleteError } = await supabase
      .from('users')
      .delete()
      .eq('id', user_id)

    if (deleteError) {
      logEvent('delete_account_error', { error: deleteError.message, user_id }, 'error')
      throw deleteError
    }

    logEvent('delete_account_success', {
      user_id,
      email: user.email,
      is_guest: user.is_guest
    }, 'info')

    // Note: Storage cleanup can be added later if needed
    // For now, CASCADE deletion is enough for database tables

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    logEvent('delete_account_unexpected_error', { error: error.message }, 'error')

    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
