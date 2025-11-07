/**
 * Get Video Jobs Endpoint
 * 
 * Purpose: Retrieve user's video generation history with pagination
 * 
 * Endpoint: GET /get-video-jobs?user_id={uuid}&limit={number}&offset={number}
 * 
 * Query Parameters:
 * - user_id (required): UUID of the user
 * - limit (optional): Number of jobs to return (default: 20)
 * - offset (optional): Number of jobs to skip (default: 0)
 * 
 * Response:
 * {
 *   "jobs": [
 *     {
 *       "job_id": "uuid",
 *       "prompt": "string",
 *       "model_name": "string",
 *       "credits_used": 4,
 *       "status": "completed",
 *       "video_url": "string|null",
 *       "thumbnail_url": "string|null",
 *       "created_at": "2025-01-XXT00:00:00Z"
 *     }
 *   ]
 * }
 * 
 * Note: Jobs are ordered by created_at DESC (newest first)
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
    const limitParam = url.searchParams.get('limit')
    const offsetParam = url.searchParams.get('offset')

    // 3. Validate required parameters
    if (!user_id) {
      logEvent('get_video_jobs_missing_user_id', {}, 'warn')
      return new Response(
        JSON.stringify({ error: 'user_id query parameter is required' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 4. Parse pagination parameters with defaults
    const limit = limitParam ? parseInt(limitParam, 10) : 20
    const offset = offsetParam ? parseInt(offsetParam, 10) : 0

    // Validate pagination values
    if (isNaN(limit) || limit < 1 || limit > 100) {
      return new Response(
        JSON.stringify({ error: 'limit must be between 1 and 100' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    if (isNaN(offset) || offset < 0) {
      return new Response(
        JSON.stringify({ error: 'offset must be >= 0' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 5. Initialize Supabase client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    logEvent('get_video_jobs_request', { 
      user_id,
      limit,
      offset 
    }, 'info')

    // 6. Query video jobs with join to models table
    const { data: jobs, error } = await supabaseClient
      .from('video_jobs')
      .select(`
        job_id,
        prompt,
        status,
        video_url,
        thumbnail_url,
        credits_used,
        created_at,
        models!inner(name)
      `)
      .eq('user_id', user_id)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    if (error) {
      logEvent('get_video_jobs_error', { 
        error: error.message,
        user_id 
      }, 'error')
      throw error
    }

    // 7. Transform response to match iOS VideoJob model
    const transformedJobs = (jobs || []).map((job: any) => {
      const model = job.models as any
      return {
        job_id: job.job_id,
        prompt: job.prompt,
        model_name: model?.name || 'Unknown Model',
        credits_used: job.credits_used,
        status: job.status,
        video_url: job.video_url,
        thumbnail_url: job.thumbnail_url,
        created_at: job.created_at
      }
    })

    logEvent('get_video_jobs_success', { 
      user_id,
      job_count: transformedJobs.length,
      limit,
      offset 
    }, 'info')

    // 8. Return transformed jobs
    return new Response(
      JSON.stringify({ jobs: transformedJobs }),
      { 
        headers: { 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    logEvent('get_video_jobs_unexpected_error', { 
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

