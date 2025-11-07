/**
 * Get User Profile Endpoint
 * 
 * Purpose: Retrieve full user profile data
 * 
 * Endpoint: GET /get-user-profile?user_id={uuid}
 * 
 * Query Parameters:
 * - user_id (required): UUID of the user
 * 
 * Response:
 * {
 *   "id": "uuid",
 *   "email": "string|null",
 *   "device_id": "string|null",
 *   "apple_sub": "string|null",
 *   "is_guest": true,
 *   "tier": "free",
 *   "credits_remaining": 10,
 *   "credits_total": 10,
 *   "initial_grant_claimed": true,
 *   "language": "en",
 *   "theme_preference": "system",
 *   "created_at": "2025-01-XXT00:00:00Z",
 *   "updated_at": "2025-01-XXT00:00:00Z"
 * }
 * 
 * Note: Returns all user fields. iOS handles snake_case to camelCase conversion.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'

serve(async (req) => {
  try {
    // 1. Validate HTTP method
    if (req.method !== 'GET') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { 
          status: 405, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 2. Parse query parameters
    const url = new URL(req.url)
    const user_id = url.searchParams.get('user_id')

    // 3. Validate required parameters
    if (!user_id) {
      logEvent('get_user_profile_missing_user_id', {}, 'warn')
      return new Response(
        JSON.stringify({ error: 'user_id query parameter is required' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 4. Initialize Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    logEvent('get_user_profile_request', { user_id }, 'info')

    // 5. Query user profile
    const { data: user, error } = await supabaseClient
      .from('users')
      .select('*')
      .eq('id', user_id)
      .single()

    if (error) {
      if (error.code === 'PGRST116') {
        // User not found
        logEvent('get_user_profile_not_found', { user_id }, 'warn')
        return new Response(
          JSON.stringify({ error: 'User not found' }),
          { 
            status: 404, 
            headers: { 'Content-Type': 'application/json' } 
          }
        )
      }

      logEvent('get_user_profile_error', { 
        error: error.message,
        user_id 
      }, 'error')
      throw error
    }

    logEvent('get_user_profile_success', { 
      user_id,
      is_guest: user.is_guest,
      credits_remaining: user.credits_remaining 
    }, 'info')

    // 6. Return user profile (no transformation needed - matches iOS User model)
    return new Response(
      JSON.stringify(user),
      { 
        headers: { 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    logEvent('get_user_profile_unexpected_error', { 
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

