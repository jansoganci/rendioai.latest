/**
 * Status Handlers
 * 
 * Handles different video job statuses and returns appropriate responses
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'
import { fetchVideoUrl, type ProviderStatus } from './video-url-fetcher.ts'

export interface JobData {
  job_id: string
  user_id: string
  model_id: string
  prompt: string
  status: string
  video_url: string | null
  thumbnail_url: string | null
  credits_used: number
  provider_job_id: string | null
  error_message: string | null
  created_at: string
  completed_at: string | null
  models: {
    provider_model_id: string
    provider: string
    name: string
  }
}

export interface StatusResponse {
  job_id: string
  status: string
  prompt: string
  model_name: string
  credits_used: number
  video_url: string | null
  thumbnail_url: string | null
  error_message?: string | null
  created_at: string
}

/**
 * Builds a standard status response from job data
 */
function buildStatusResponse(job: JobData): StatusResponse {
  const model = job.models as any
  return {
    job_id: job.job_id,
    status: job.status,
    prompt: job.prompt,
    model_name: model?.name || '',
    credits_used: job.credits_used,
    video_url: job.video_url,
    thumbnail_url: job.thumbnail_url,
    error_message: job.error_message,
    created_at: job.created_at
  }
}

/**
 * Handles completed or failed status (no provider check needed)
 */
export function handleFinalStatus(job: JobData): StatusResponse {
  return buildStatusResponse(job)
}

/**
 * Handles pending/processing status when no provider_job_id exists
 */
export function handlePendingWithoutProvider(job: JobData): StatusResponse {
  logEvent('get_video_status_no_provider_job_id', { job_id: job.job_id }, 'warn')
  return buildStatusResponse(job)
}

/**
 * Handles COMPLETED status from provider
 */
export async function handleCompletedStatus(
  job: JobData,
  providerStatus: ProviderStatus,
  supabaseClient: ReturnType<typeof createClient>
): Promise<StatusResponse | null> {
  const model = job.models as any
  
  // Fetch video URL using multiple strategies
  const { videoUrl } = await fetchVideoUrl(
    providerStatus,
    model.provider_model_id,
    job.provider_job_id!,
    job.job_id
  )

  if (videoUrl) {
    // Update job in database with video URL
    const { error: updateError } = await supabaseClient
      .from('video_jobs')
      .update({
        status: 'completed',
        video_url: videoUrl,
        thumbnail_url: null, // Skip thumbnails for Phase 2
        completed_at: new Date().toISOString()
      })
      .eq('job_id', job.job_id)

    if (updateError) {
      console.error('[status-handlers] Database update error:', updateError.message)
      logEvent('get_video_status_update_error', {
        job_id: job.job_id,
        error: updateError.message
      }, 'error')
      // Continue anyway - return the video URL
    }

    logEvent('video_generation_completed', {
      job_id: job.job_id,
      provider_job_id: job.provider_job_id,
      video_url: videoUrl
    })

    return {
      ...buildStatusResponse(job),
      status: 'completed',
      video_url: videoUrl,
      thumbnail_url: null
    }
  } else {
    // Video URL not found - don't update status, keep as processing for retry
    console.error('[status-handlers] Video URL not found after COMPLETED status', {
      job_id: job.job_id,
      provider_job_id: job.provider_job_id
    })
    
    logEvent('video_url_missing_after_completion', {
      job_id: job.job_id,
      provider_job_id: job.provider_job_id
    }, 'error')
    
    // Return null to indicate we should keep current status
    return null
  }
}

/**
 * Handles FAILED status from provider
 */
export async function handleFailedStatus(
  job: JobData,
  providerStatus: ProviderStatus,
  supabaseClient: ReturnType<typeof createClient>
): Promise<StatusResponse> {
  const errorMessage = providerStatus.error || 'Video generation failed'
  
  const { error: updateError } = await supabaseClient
    .from('video_jobs')
    .update({
      status: 'failed',
      error_message: errorMessage
    })
    .eq('job_id', job.job_id)

  if (updateError) {
    logEvent('get_video_status_failed_update_error', {
      job_id: job.job_id,
      error: updateError.message
    }, 'error')
  }

  logEvent('video_generation_failed', {
    job_id: job.job_id,
    provider_job_id: job.provider_job_id,
    error: errorMessage
  })

  // Note: Credits already deducted, but we could refund here if needed
  // For now, we'll handle refunds in Phase 6 (retry logic)

  return {
    ...buildStatusResponse(job),
    status: 'failed',
    video_url: null,
    thumbnail_url: null,
    error_message: errorMessage
  }
}

/**
 * Handles IN_PROGRESS or IN_QUEUE status from provider
 */
export async function handleInProgressStatus(
  job: JobData,
  providerStatus: ProviderStatus,
  supabaseClient: ReturnType<typeof createClient>
): Promise<StatusResponse> {
  // Update status to "processing" if it's in progress
  if (providerStatus.status === 'IN_PROGRESS' && job.status === 'pending') {
    await supabaseClient
      .from('video_jobs')
      .update({ status: 'processing' })
      .eq('job_id', job.job_id)
  }

  // Determine final status
  const finalStatus = job.status === 'pending' && providerStatus.status === 'IN_PROGRESS'
    ? 'processing'
    : job.status

  return {
    ...buildStatusResponse(job),
    status: finalStatus
  }
}

/**
 * Handles provider check errors - returns current DB status
 */
export function handleProviderError(job: JobData, error: any): StatusResponse {
  logEvent('get_video_status_provider_check_failed', {
    job_id: job.job_id,
    provider_job_id: job.provider_job_id,
    error: error.message
  }, 'error')

  // Don't fail the request - return current status
  return buildStatusResponse(job)
}

