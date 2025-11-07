/**
 * Get Models Endpoint
 * 
 * Purpose: Retrieve all available video generation models
 * 
 * Endpoint: GET /get-models
 * 
 * Query Parameters: None (public endpoint)
 * 
 * Response:
 * {
 *   "models": [
 *     {
 *       "id": "uuid",
 *       "name": "string",
 *       "category": "string",
 *       "thumbnail_url": "string|null",
 *       "is_featured": true
 *     }
 *   ]
 * }
 * 
 * Note: Returns only available models, ordered by featured status then name.
 * This replaces direct REST API calls for better consistency and future enhancements.
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

    // 2. Initialize Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    logEvent('get_models_request', {}, 'info')

    // 3. Query available models
    // Order: Featured first, then alphabetical by name
    const { data: models, error } = await supabaseClient
      .from('models')
      .select('id, name, category, thumbnail_url, is_featured')
      .eq('is_available', true)
      .order('is_featured', { ascending: false })
      .order('name', { ascending: true })

    if (error) {
      logEvent('get_models_error', { 
        error: error.message 
      }, 'error')
      throw error
    }

    logEvent('get_models_success', { 
      model_count: models?.length || 0 
    }, 'info')

    // 4. Return models (no transformation needed - matches iOS ModelPreview model)
    return new Response(
      JSON.stringify({ models: models || [] }),
      { 
        headers: { 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    logEvent('get_models_unexpected_error', { 
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

