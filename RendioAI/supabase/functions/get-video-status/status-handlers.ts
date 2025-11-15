/**
 * Status Handlers
 *
 * Handles different video job statuses and returns appropriate responses
 * Includes video migration from FalAI to Supabase Storage
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createLogger } from '../_shared/logger.ts'
import { migrateVideoToStorage } from '../_shared/storage-utils.ts'
import { fetchVideoUrl, type ProviderStatus } from './video-url-fetcher.ts'

const logger = createLogger('status-handlers')

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
  logger.warn('No provider job ID found', {
    job_id: job.job_id,
    user_id: job.user_id
  })
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
    // Attempt to migrate video to Supabase Storage
    let finalVideoUrl = videoUrl
    let migrationSuccess = false

    // Only attempt migration if we have a FalAI URL
    if (videoUrl.includes('fal.ai') || videoUrl.includes('fal.run')) {
      logger.info('Attempting video migration from FalAI', {
        job_id: job.job_id,
        user_id: job.user_id,
        metadata: { original_url: videoUrl }
      })

      const migrationResult = await migrateVideoToStorage(
        videoUrl,
        job.user_id,
        job.job_id
      )

      if (migrationResult.success && migrationResult.url) {
        finalVideoUrl = migrationResult.url
        migrationSuccess = true
        logger.info('Video migration successful', {
          job_id: job.job_id,
          user_id: job.user_id,
          metadata: {
            new_url: finalVideoUrl,
            duration_ms: migrationResult.duration,
            size_mb: migrationResult.videoSize ? (migrationResult.videoSize / (1024 * 1024)).toFixed(2) : undefined
          }
        })
      } else {
        // Migration failed, but keep FalAI URL (graceful degradation)
        logger.warn('Video migration failed, using FalAI URL', {
          job_id: job.job_id,
          user_id: job.user_id,
          metadata: {
            error: migrationResult.error,
            duration_ms: migrationResult.duration
          }
        })
      }
    }

    // Update job in database with final video URL
    const { error: updateError } = await supabaseClient
      .from('video_jobs')
      .update({
        status: 'completed',
        video_url: finalVideoUrl,
        thumbnail_url: null, // Skip thumbnails for Phase 2
        completed_at: new Date().toISOString(),
        // Add metadata about migration
        metadata: {
          migration_attempted: videoUrl !== finalVideoUrl || migrationSuccess,
          migration_success: migrationSuccess,
          original_url: migrationSuccess ? videoUrl : undefined
        }
      })
      .eq('job_id', job.job_id)

    if (updateError) {
      logger.error('Database update error', updateError, {
        job_id: job.job_id,
        user_id: job.user_id
      })
      // Continue anyway - return the video URL
    }

    logger.info('Video generation completed', {
      job_id: job.job_id,
      user_id: job.user_id,
      metadata: {
        provider_job_id: job.provider_job_id,
        video_url: finalVideoUrl,
        migration_success: migrationSuccess
      }
    })

    return {
      ...buildStatusResponse(job),
      status: 'completed',
      video_url: finalVideoUrl,
      thumbnail_url: null
    }
  } else {
    // Video URL not found - don't update status, keep as processing for retry
    logger.error('Video URL not found after COMPLETED status', undefined, {
      job_id: job.job_id,
      user_id: job.user_id,
      metadata: { provider_job_id: job.provider_job_id }
    })

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
    logger.error('Failed to update job status', updateError, {
      job_id: job.job_id,
      user_id: job.user_id
    })
  }

  logger.error('Video generation failed', undefined, {
    job_id: job.job_id,
    user_id: job.user_id,
    metadata: {
      provider_job_id: job.provider_job_id,
      error: errorMessage
    }
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
  logger.error('Provider check failed', error, {
    job_id: job.job_id,
    user_id: job.user_id,
    metadata: { provider_job_id: job.provider_job_id }
  })

  // Don't fail the request - return current status
  return buildStatusResponse(job)
}

