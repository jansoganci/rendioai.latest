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

// Phase 5 Debug Helpers (toggle via env DEBUG_PHASE5=true)
const DEBUG_PHASE5 = Deno.env.get('DEBUG_PHASE5') === 'true'
function p5log(...args: any[]) { if (DEBUG_PHASE5) console.log(...args) }
function p5time(label: string) { const t = Date.now(); return () => Date.now() - t }

serve(async (req) => {
  const tAll = p5time('get-models')
  const requestId = crypto.randomUUID()

  try {
    // STEP A: Entry
    p5log('[P5][GetModels][ENTRY]', { requestId })

    // 1. Validate HTTP method
    if (req.method !== 'GET') {
      p5log('[P5][GetModels][ERR]', { step: 'method_validation', requestId })
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
      p5log('[P5][GetModels][ERR]', { step: 'db_query', msg: error.message, requestId })
      logEvent('get_models_error', {
        error: error.message
      }, 'error')
      throw error
    }

    // STEP B: DB result
    p5log('[P5][GetModels][DB][OK]', { count: models?.length || 0, requestId })

    logEvent('get_models_success', {
      model_count: models?.length || 0
    }, 'info')

    // 4. Generate ETag from models content
    // STEP C: ETag build
    p5log('[P5][GetModels][ETag][BUILD]', { requestId })
    const content = JSON.stringify(models || [])
    const encoder = new TextEncoder()
    const data = encoder.encode(content)
    const hashBuffer = await crypto.subtle.digest('MD5', data)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
    const etag = `"${hashHex}"`

    // 5. Check If-None-Match header for cache validation
    const clientETag = req.headers.get('If-None-Match')

    if (clientETag === etag) {
      // Content hasn't changed - return 304 Not Modified
      // STEP D: ETag hit
      p5log('[P5][GetModels][ETag][HIT]', { etag, requestId })
      p5log('[P5][GetModels][EXIT]', { status: 304, totalMs: tAll(), requestId })
      logEvent('get_models_cache_hit', { etag }, 'info')
      return new Response(null, {
        status: 304,
        headers: {
          'ETag': etag,
          'Cache-Control': 'public, max-age=3600'
        }
      })
    }

    // 6. Return models with ETag and Cache-Control headers
    // STEP E: ETag miss
    p5log('[P5][GetModels][ETag][MISS]', { etag, size: content.length, requestId })
    p5log('[P5][GetModels][EXIT]', { status: 200, totalMs: tAll(), requestId })
    return new Response(
      JSON.stringify({ models: models || [] }),
      {
        headers: {
          'Content-Type': 'application/json',
          'ETag': etag,
          'Cache-Control': 'public, max-age=3600'
        }
      }
    )

  } catch (error) {
    p5log('[P5][GetModels][ERR]', { msg: error.message, requestId })
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

