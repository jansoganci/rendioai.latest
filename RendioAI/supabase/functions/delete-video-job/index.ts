/**
 * Delete Video Job Endpoint
 * 
 * Purpose: Delete a video job from user's history
 * 
 * Endpoint: POST /delete-video-job
 * 
 * Request Body:
 * {
 *   "job_id": "uuid",
 *   "user_id": "uuid"
 * }
 * 
 * Response:
 * {
 *   "success": true
 * }
 * 
 * Note: Verifies ownership before deletion. Storage deletion (video files) is TODO for future.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'

serve(async (req) => {
  try {
    // 1. Validate HTTP method
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { 
          status: 405, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 2. Parse request body
    let body: { job_id?: string; user_id?: string }
    try {
      body = await req.json()
    } catch (jsonError) {
      logEvent('delete_video_job_invalid_json', { 
        error: jsonError.message 
      }, 'error')
      return new Response(
        JSON.stringify({ 
          error: 'Invalid JSON in request body',
          details: jsonError.message 
        }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    const { job_id, user_id } = body

    // 3. Validate required fields
    if (!job_id || !user_id) {
      logEvent('delete_video_job_missing_fields', { 
        has_job_id: !!job_id,
        has_user_id: !!user_id 
      }, 'warn')
      return new Response(
        JSON.stringify({ error: 'job_id and user_id are required' }),
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

    logEvent('delete_video_job_request', { 
      job_id,
      user_id 
    }, 'info')

    // 5. Verify ownership - check if job exists and belongs to user
    const { data: job, error: jobError } = await supabaseClient
      .from('video_jobs')
      .select('user_id, video_url, thumbnail_url')
      .eq('job_id', job_id)
      .single()

    if (jobError || !job) {
      logEvent('delete_video_job_not_found', { 
        job_id,
        error: jobError?.message 
      }, 'warn')
      return new Response(
        JSON.stringify({ error: 'Job not found' }),
        { 
          status: 404, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 6. Verify ownership
    if (job.user_id !== user_id) {
      logEvent('delete_video_job_unauthorized', { 
        job_id,
        job_user_id: job.user_id,
        request_user_id: user_id 
      }, 'warn')
      return new Response(
        JSON.stringify({ error: 'Job not found or unauthorized' }),
        { 
          status: 404, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 7. Delete video from storage (if exists) - TODO for future
    // Note: For Phase 3, we skip storage deletion to keep it simple
    // Future: Extract path from video_url and delete from Supabase Storage buckets
    if (job.video_url) {
      logEvent('delete_video_job_storage_skip', { 
        job_id,
        video_url: job.video_url,
        note: 'Storage deletion not implemented yet' 
      }, 'info')
      // TODO: Implement storage deletion
      // Example:
      // const videoPath = extractPathFromURL(job.video_url)
      // await supabaseClient.storage.from('videos').remove([videoPath])
      // if (job.thumbnail_url) {
      //   const thumbnailPath = extractPathFromURL(job.thumbnail_url)
      //   await supabaseClient.storage.from('thumbnails').remove([thumbnailPath])
      // }
    }

    // 8. Delete job record from database
    const { error: deleteError } = await supabaseClient
      .from('video_jobs')
      .delete()
      .eq('job_id', job_id)

    if (deleteError) {
      logEvent('delete_video_job_error', { 
        error: deleteError.message,
        job_id 
      }, 'error')
      throw deleteError
    }

    logEvent('delete_video_job_success', { 
      job_id,
      user_id 
    }, 'info')

    // 9. Return success response
    return new Response(
      JSON.stringify({ success: true }),
      { 
        headers: { 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    logEvent('delete_video_job_unexpected_error', { 
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

