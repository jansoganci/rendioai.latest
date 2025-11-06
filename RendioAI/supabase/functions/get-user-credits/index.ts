/**
 * Get User Credits Endpoint
 * 
 * Purpose: Retrieve user's current credit balance
 * 
 * Endpoint: GET /get-user-credits?user_id={uuid}
 * 
 * Query Parameters:
 * - user_id (required): UUID of the user
 * 
 * Response:
 * {
 *   "credits_remaining": 10
 * }
 * 
 * Note: This is a simple read-only endpoint for checking credit balance.
 * For full user profile, use get-user-profile endpoint (Phase 3).
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'

serve(async (req) => {
  try {
    // Only allow GET requests
    if (req.method !== 'GET') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { 
          status: 405, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // Parse query parameters
    const url = new URL(req.url)
    const user_id = url.searchParams.get('user_id')

    // Validate input
    if (!user_id) {
      return new Response(
        JSON.stringify({ error: 'user_id query parameter is required' }),
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

    logEvent('get_user_credits_request', { user_id }, 'info')

    // Query user's credit balance
    const { data: user, error } = await supabaseClient
      .from('users')
      .select('credits_remaining')
      .eq('id', user_id)
      .single()

    if (error) {
      if (error.code === 'PGRST116') {
        // User not found
        logEvent('get_user_credits_not_found', { user_id }, 'warn')
        return new Response(
          JSON.stringify({ error: 'User not found' }),
          { 
            status: 404, 
            headers: { 'Content-Type': 'application/json' } 
          }
        )
      }

      logEvent('get_user_credits_error', { 
        error: error.message,
        user_id 
      }, 'error')
      throw error
    }

    logEvent('get_user_credits_success', { 
      user_id,
      credits_remaining: user.credits_remaining 
    }, 'info')

    // Return credit balance
    return new Response(
      JSON.stringify({ 
        credits_remaining: user.credits_remaining 
      }),
      { 
        headers: { 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    logEvent('get_user_credits_unexpected_error', { 
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

