/**
 * Video URL Fetcher
 * 
 * Handles fetching video URLs from FalAI with multiple fallback strategies
 */

import { logEvent } from '../_shared/logger.ts'
import { getFalAIResult } from '../_shared/falai-adapter.ts'

export interface ProviderStatus {
  status: string
  video?: { url?: string }
  response_url?: string
  error?: string
}

export interface VideoUrlResult {
  videoUrl: string | null
  result?: any
}

/**
 * Fetches video URL from FalAI provider status
 * Uses multiple fallback strategies:
 * 1. Check if video URL is already in providerStatus
 * 2. Fetch from response_url (most reliable)
 * 3. Fall back to getFalAIResult
 */
export async function fetchVideoUrl(
  providerStatus: ProviderStatus,
  providerModelId: string,
  providerJobId: string,
  jobId: string
): Promise<VideoUrlResult> {
  let videoUrl = providerStatus.video?.url
  let result: any = null

  // Strategy 1: Check if video URL is already in providerStatus
  if (videoUrl) {
    return { videoUrl, result }
  }

  // Strategy 2: Fetch from response_url (most reliable)
  if (providerStatus.response_url) {
    try {
      const apiKey = Deno.env.get('FALAI_API_KEY')
      if (apiKey) {
        const responseUrlResponse = await fetch(providerStatus.response_url, {
          method: 'GET',
          headers: {
            'Authorization': `Key ${apiKey}`,
            'Content-Type': 'application/json'
          }
        })

        if (responseUrlResponse.ok) {
          const responseUrlData = await responseUrlResponse.json()
          videoUrl = responseUrlData.video?.url
          if (videoUrl) {
            result = {
              video: responseUrlData.video,
              video_id: responseUrlData.video_id
            }
            return { videoUrl, result }
          }
        }
      }
    } catch (responseUrlError: any) {
      console.error('[video-url-fetcher] Error fetching from response_url:', responseUrlError.message)
    }
  }

  // Strategy 3: Fall back to getFalAIResult
  if (!videoUrl) {
    try {
      result = await getFalAIResult(providerModelId, providerJobId)
      videoUrl = result.video?.url
      
      if (videoUrl) {
        return { videoUrl, result }
      }
    } catch (resultError: any) {
      console.error('[video-url-fetcher] Error calling getFalAIResult:', resultError.message)
      
      logEvent('get_falai_result_error', {
        job_id: jobId,
        provider_job_id: providerJobId,
        error: resultError.message
      }, 'error')
    }
  }

  // No video URL found
  if (!videoUrl) {
    console.error('[video-url-fetcher] Video URL not found after all strategies', {
      job_id: jobId,
      provider_job_id: providerJobId
    })
    
    logEvent('video_url_missing_after_completion', {
      job_id: jobId,
      provider_job_id: providerJobId
    }, 'error')
  }

  return { videoUrl: null, result }
}

