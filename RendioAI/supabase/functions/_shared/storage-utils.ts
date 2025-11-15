/**
 * Storage Utilities Module
 * Provides functions for migrating videos from FalAI to Supabase Storage
 * with timeout handling and graceful degradation
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createLogger, logVideoMigration } from './logger.ts'
import { alertVideoMigrationFailure, alertStorageUsage } from './telegram.ts'
import { captureException, measurePerformance } from './sentry.ts'

const logger = createLogger('storage-utils')

// Constants for timeout and size limits
const MAX_SYNC_VIDEO_SIZE = 10 * 1024 * 1024  // 10MB
const MIGRATION_TIMEOUT = 30000  // 30 seconds
const DOWNLOAD_TIMEOUT = 20000   // 20 seconds
const UPLOAD_TIMEOUT = 25000     // 25 seconds

interface VideoMigrationResult {
  success: boolean
  url?: string
  error?: string
  duration: number
  videoSize?: number
}

/**
 * Download video from URL with timeout handling
 */
export async function downloadVideoFromUrl(
  url: string,
  timeoutMs: number = DOWNLOAD_TIMEOUT
): Promise<{ data: ArrayBuffer; size: number } | { error: string }> {
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs)

  try {
    logger.debug('Starting video download', {
      metadata: { url, timeout_ms: timeoutMs }
    })

    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'RendioAI-VideoMigration/1.0'
      }
    })

    clearTimeout(timeoutId)

    if (!response.ok) {
      const error = `Failed to download video: ${response.status} ${response.statusText}`
      logger.error('Video download failed', new Error(error), {
        metadata: { url, status: response.status }
      })
      return { error }
    }

    // Check content length
    const contentLength = response.headers.get('content-length')
    const size = contentLength ? parseInt(contentLength, 10) : 0

    if (size > MAX_SYNC_VIDEO_SIZE) {
      logger.warn('Video too large for sync migration', {
        metadata: {
          url,
          size_mb: (size / (1024 * 1024)).toFixed(2),
          max_mb: (MAX_SYNC_VIDEO_SIZE / (1024 * 1024)).toFixed(2)
        }
      })
      return { error: `Video too large: ${(size / (1024 * 1024)).toFixed(2)}MB` }
    }

    const data = await response.arrayBuffer()

    logger.debug('Video downloaded successfully', {
      metadata: {
        url,
        size_mb: (size / (1024 * 1024)).toFixed(2)
      }
    })

    return { data, size }
  } catch (error) {
    clearTimeout(timeoutId)

    if (error.name === 'AbortError') {
      const errorMsg = `Download timeout after ${timeoutMs}ms`
      logger.error('Video download timeout', new Error(errorMsg), {
        metadata: { url, timeout_ms: timeoutMs }
      })
      return { error: errorMsg }
    }

    logger.error('Video download error', error as Error, {
      metadata: { url }
    })
    return { error: error.message }
  }
}

/**
 * Upload video to Supabase Storage
 */
export async function uploadVideoToStorage(
  data: ArrayBuffer,
  userId: string,
  jobId: string,
  bucket: string = 'videos'
): Promise<{ url: string } | { error: string }> {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Generate path: {bucket}/{userId}/{YYYY-MM}/{jobId}.mp4
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    const path = `${userId}/${year}-${month}/${jobId}.mp4`

    logger.debug('Uploading video to storage', {
      user_id: userId,
      job_id: jobId,
      metadata: { bucket, path, size_mb: (data.byteLength / (1024 * 1024)).toFixed(2) }
    })

    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(path, data, {
        contentType: 'video/mp4',
        upsert: true  // Overwrite if exists
      })

    if (uploadError) {
      logger.error('Video upload failed', uploadError as Error, {
        user_id: userId,
        job_id: jobId,
        metadata: { bucket, path }
      })
      return { error: uploadError.message }
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from(bucket)
      .getPublicUrl(path)

    if (!urlData?.publicUrl) {
      return { error: 'Failed to get public URL' }
    }

    logger.info('Video uploaded successfully', {
      user_id: userId,
      job_id: jobId,
      metadata: { bucket, path, url: urlData.publicUrl }
    })

    return { url: urlData.publicUrl }
  } catch (error) {
    logger.error('Video upload error', error as Error, {
      user_id: userId,
      job_id: jobId
    })
    return { error: error.message }
  }
}

/**
 * Get public URL for a storage object
 */
export function getPublicUrl(
  bucket: string,
  path: string
): string {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )

  const { data } = supabase.storage
    .from(bucket)
    .getPublicUrl(path)

  return data.publicUrl
}

/**
 * Migrate video from FalAI to Supabase Storage with timeout handling
 * Hybrid approach: Try sync migration if video is small enough, otherwise fail gracefully
 */
export async function migrateVideoToStorage(
  falaiUrl: string,
  userId: string,
  jobId: string
): Promise<VideoMigrationResult> {
  const startTime = Date.now()

  try {
    // Use measurePerformance from Sentry for monitoring
    return await measurePerformance(
      'video_migration',
      async () => {
        // Step 1: Download video from FalAI
        const downloadResult = await downloadVideoFromUrl(falaiUrl, DOWNLOAD_TIMEOUT)

        if ('error' in downloadResult) {
          const duration = Date.now() - startTime

          // Log failure but don't alert for size issues (expected behavior)
          if (downloadResult.error.includes('too large')) {
            logVideoMigration(logger, jobId, userId, false, duration, {
              error: downloadResult.error,
              fromUrl: falaiUrl
            })
          } else {
            // Alert for unexpected failures
            await alertVideoMigrationFailure(
              jobId,
              userId,
              new Error(downloadResult.error),
              falaiUrl
            )
          }

          return {
            success: false,
            error: downloadResult.error,
            duration
          }
        }

        // Step 2: Upload to Supabase Storage
        const uploadResult = await uploadVideoToStorage(
          downloadResult.data,
          userId,
          jobId
        )

        const duration = Date.now() - startTime

        if ('error' in uploadResult) {
          logVideoMigration(logger, jobId, userId, false, duration, {
            error: uploadResult.error,
            fromUrl: falaiUrl,
            videoSize: downloadResult.size
          })

          await alertVideoMigrationFailure(
            jobId,
            userId,
            new Error(uploadResult.error),
            falaiUrl
          )

          return {
            success: false,
            error: uploadResult.error,
            duration,
            videoSize: downloadResult.size
          }
        }

        // Success!
        logVideoMigration(logger, jobId, userId, true, duration, {
          fromUrl: falaiUrl,
          toUrl: uploadResult.url,
          videoSize: downloadResult.size
        })

        return {
          success: true,
          url: uploadResult.url,
          duration,
          videoSize: downloadResult.size
        }
      },
      { user_id: userId, job_id: jobId }
    )
  } catch (error) {
    const duration = Date.now() - startTime

    captureException(error, {
      user_id: userId,
      job_id: jobId,
      action: 'video_migration',
      metadata: { falai_url: falaiUrl, duration }
    })

    logVideoMigration(logger, jobId, userId, false, duration, {
      error: error.message,
      fromUrl: falaiUrl
    })

    // Don't alert for timeout errors (expected behavior)
    if (!error.message?.includes('timeout')) {
      await alertVideoMigrationFailure(jobId, userId, error as Error, falaiUrl)
    }

    return {
      success: false,
      error: error.message,
      duration
    }
  }
}

/**
 * Check storage usage and alert if needed
 */
export async function checkAndAlertStorageUsage(): Promise<void> {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Note: Supabase doesn't provide direct storage usage API
    // This would need to be implemented via database tracking or custom solution
    // For now, this is a placeholder that could be enhanced

    // Example implementation tracking via database:
    const { data, error } = await supabase
      .from('storage_usage')
      .select('used_bytes, total_bytes')
      .single()

    if (error || !data) {
      logger.warn('Could not fetch storage usage', { metadata: { error } })
      return
    }

    const usedGB = data.used_bytes / (1024 * 1024 * 1024)
    const totalGB = data.total_bytes / (1024 * 1024 * 1024)
    const percentage = Math.round((data.used_bytes / data.total_bytes) * 100)

    // Alert if usage is high
    if (percentage >= 80) {
      await alertStorageUsage(usedGB, totalGB, percentage)
    }

    // Log for monitoring
    logger.info(`Storage usage: ${percentage}% (${usedGB.toFixed(2)}GB / ${totalGB.toFixed(2)}GB)`, {
      metadata: { used_gb: usedGB, total_gb: totalGB, percentage }
    })
  } catch (error) {
    logger.error('Failed to check storage usage', error as Error)
  }
}

/**
 * Delete video from storage (for cleanup)
 */
export async function deleteVideoFromStorage(
  bucket: string,
  path: string
): Promise<boolean> {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { error } = await supabase.storage
      .from(bucket)
      .remove([path])

    if (error) {
      logger.error('Failed to delete video', error as Error, {
        metadata: { bucket, path }
      })
      return false
    }

    logger.info('Video deleted from storage', {
      metadata: { bucket, path }
    })

    return true
  } catch (error) {
    logger.error('Error deleting video', error as Error, {
      metadata: { bucket, path }
    })
    return false
  }
}