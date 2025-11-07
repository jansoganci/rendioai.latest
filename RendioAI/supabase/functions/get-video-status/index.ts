/**
 * Get Video Status Endpoint
 * 
 * Polls video generation progress and updates job status in database.
 * Checks FalAI queue status and updates job when completed.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'
import { checkFalAIStatus } from '../_shared/falai-adapter.ts'
import {
  handleFinalStatus,
  handlePendingWithoutProvider,
  handleCompletedStatus,
  handleFailedStatus,
  handleInProgressStatus,
  handleProviderError,
  type JobData
} from './status-handlers.ts'

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

    // 2. Get job_id from query params
    const url = new URL(req.url)
    const job_id = url.searchParams.get('job_id')
    
    if (!job_id) {
      logEvent('get_video_status_missing_job_id', {}, 'warn')
      return new Response(
        JSON.stringify({ error: 'job_id query parameter required' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 3. Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 4. Get job from database
    const { data: job, error: jobError } = await supabaseClient
      .from('video_jobs')
      .select(`
        job_id,
        user_id,
        model_id,
        prompt,
        status,
        video_url,
        thumbnail_url,
        credits_used,
        provider_job_id,
        error_message,
        created_at,
        completed_at,
        models!inner(provider_model_id, provider, name)
      `)
      .eq('job_id', job_id)
      .single()

    if (jobError || !job) {
      logEvent('get_video_status_job_not_found', { 
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

    const jobData = job as unknown as JobData
      
    // 5. If job is already completed or failed, return current status
    if (jobData.status === 'completed' || jobData.status === 'failed') {
      const response = handleFinalStatus(jobData)
      return new Response(
        JSON.stringify(response),
        { 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 6. If still pending/processing, check FalAI status
    if (jobData.status === 'pending' || jobData.status === 'processing') {
      // No provider_job_id - return current status
      if (!jobData.provider_job_id) {
        const response = handlePendingWithoutProvider(jobData)
        return new Response(
          JSON.stringify(response),
          { 
            headers: { 'Content-Type': 'application/json' } 
          }
        )
      }

      try {
        const model = jobData.models as any
        const providerStatus = await checkFalAIStatus(
          model.provider_model_id,
          jobData.provider_job_id
        )

        logEvent('falai_status_check', {
          job_id,
          provider_job_id: jobData.provider_job_id,
          falai_status: providerStatus.status
        })

        // Handle different provider statuses
        if (providerStatus.status === 'COMPLETED') {
          const response = await handleCompletedStatus(
            jobData,
            providerStatus,
            supabaseClient
          )

          // If video URL not found, keep current status (don't update)
          if (response) {
            return new Response(
              JSON.stringify(response),
              { 
                headers: { 'Content-Type': 'application/json' } 
              }
            )
          }
          // Fall through to return current status if video URL not found
        }

        if (providerStatus.status === 'FAILED') {
          const response = await handleFailedStatus(
            jobData,
            providerStatus,
            supabaseClient
          )
          return new Response(
            JSON.stringify(response),
            { 
              headers: { 'Content-Type': 'application/json' } 
            }
          )
        }

        // Handle IN_PROGRESS or IN_QUEUE
        const response = await handleInProgressStatus(
          jobData,
          providerStatus,
          supabaseClient
        )
        return new Response(
          JSON.stringify(response),
          { 
            headers: { 'Content-Type': 'application/json' } 
          }
        )

      } catch (providerError) {
        // If provider check fails, return current DB status
        const response = handleProviderError(jobData, providerError)
        return new Response(
          JSON.stringify(response),
          { 
            headers: { 'Content-Type': 'application/json' } 
          }
        )
      }
    }

    // 7. Fallback: Return current status
    const response = handleFinalStatus(jobData)
    return new Response(
      JSON.stringify(response),
      { 
        headers: { 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    logEvent('get_video_status_error', { 
      error: error.message,
      stack: error.stack 
    }, 'error')
    
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
})
