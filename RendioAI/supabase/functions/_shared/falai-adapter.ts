/**
 * FalAI Sora 2 Image-to-Video Adapter
 * 
 * Handles communication with FalAI's queue API for Sora 2 model
 */

interface FalAIQueueRequest {
  prompt: string
  image_url: string
  resolution?: 'auto' | '720p'
  aspect_ratio?: 'auto' | '9:16' | '16:9'
  duration?: 4 | 8 | 12
}

interface FalAIQueueResponse {
  request_id: string
  status: 'IN_QUEUE' | 'IN_PROGRESS' | 'COMPLETED' | 'FAILED'
}

interface FalAIStatusResponse {
  status: 'IN_QUEUE' | 'IN_PROGRESS' | 'COMPLETED' | 'FAILED'
  video?: {
    url: string
    content_type?: string
    width?: number
    height?: number
    fps?: number
    duration?: number
  }
  video_id?: string
  error?: string
  response_url?: string // URL to fetch the final result when COMPLETED
}

/**
 * Submit a video generation job to FalAI Queue API
 */
export async function submitFalAIJob(
  modelId: string,
  prompt: string,
  imageUrl: string,
  settings?: {
    resolution?: 'auto' | '720p'
    aspect_ratio?: 'auto' | '9:16' | '16:9'
    duration?: 4 | 8 | 12
  }
): Promise<FalAIQueueResponse> {
  const apiKey = Deno.env.get('FALAI_API_KEY')
  
  if (!apiKey) {
    throw new Error('FALAI_API_KEY environment variable not set')
  }

  // Default settings for Sora 2
  const requestBody: FalAIQueueRequest = {
    prompt,
    image_url: imageUrl,
    resolution: settings?.resolution || 'auto',
    aspect_ratio: settings?.aspect_ratio || 'auto',
    duration: settings?.duration || 4
  }

  const response = await fetch(
    `https://queue.fal.run/${modelId}`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Key ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestBody)
    }
  )

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`FalAI API error: ${response.status} ${response.statusText} - ${errorText}`)
  }

  const data = await response.json()
  
  return {
    request_id: data.request_id || data.id,
    status: data.status || 'IN_QUEUE'
  }
}

/**
 * Check the status of a FalAI job
 */
export async function checkFalAIStatus(
  modelId: string,
  requestId: string
): Promise<FalAIStatusResponse> {
  const apiKey = Deno.env.get('FALAI_API_KEY')
  
  if (!apiKey) {
    throw new Error('FALAI_API_KEY environment variable not set')
  }

  // FalAI queue API uses this format: https://queue.fal.run/{model_base}/requests/{request_id}/status
  // The model ID might be "fal-ai/sora-2/image-to-video" but the URL needs "fal-ai/sora-2"
  // Extract the base model path (remove the last segment if it's a variant)
  let modelBase = modelId
  if (modelId.includes('/image-to-video')) {
    modelBase = modelId.replace('/image-to-video', '')
  }
  
  // Use the correct FalAI queue status endpoint format
  const statusUrl = `https://queue.fal.run/${modelBase}/requests/${requestId}/status`

  const response = await fetch(
    statusUrl,
    {
      method: 'GET',
      headers: {
        'Authorization': `Key ${apiKey}`,
        'Content-Type': 'application/json'
      }
    }
  )

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`FalAI status check error: ${response.status} ${response.statusText} - ${errorText}`)
  }

  const data = await response.json()
  
  // Map FalAI status to our internal status
  let status: 'IN_QUEUE' | 'IN_PROGRESS' | 'COMPLETED' | 'FAILED'
  
  if (data.status === 'COMPLETED' || data.status === 'DONE') {
    status = 'COMPLETED'
  } else if (data.status === 'FAILED' || data.status === 'ERROR') {
    status = 'FAILED'
  } else if (data.status === 'IN_PROGRESS' || data.status === 'PROCESSING') {
    status = 'IN_PROGRESS'
  } else {
    status = 'IN_QUEUE'
  }

  // Check if video URL is in the response
  let videoUrl: string | undefined
  let videoData: any = undefined

  // Check direct video property
  if (data.video?.url) {
    videoUrl = data.video.url
    videoData = data.video
  }

  const result = {
    status,
    video: videoData ? {
      url: videoData.url,
      content_type: videoData.content_type,
      width: videoData.width,
      height: videoData.height,
      fps: videoData.fps,
      duration: videoData.duration
    } : undefined,
    video_id: data.video_id,
    error: data.error || data.message,
    response_url: data.response_url // Include this so we can fetch video if needed
  }
  
  return result
}

/**
 * Get the result of a completed FalAI job
 */
export async function getFalAIResult(
  modelId: string,
  requestId: string
): Promise<FalAIStatusResponse> {
  const apiKey = Deno.env.get('FALAI_API_KEY')
  
  if (!apiKey) {
    throw new Error('FALAI_API_KEY environment variable not set')
  }

  // FalAI queue API uses this format: https://queue.fal.run/{model_base}/requests/{request_id}/response
  // Extract the base model path (remove the last segment if it's a variant)
  let modelBase = modelId
  if (modelId.includes('/image-to-video')) {
    modelBase = modelId.replace('/image-to-video', '')
  }
  
  const responseUrl = `https://queue.fal.run/${modelBase}/requests/${requestId}/response`

  const response = await fetch(
    responseUrl,
    {
      method: 'GET',
      headers: {
        'Authorization': `Key ${apiKey}`,
        'Content-Type': 'application/json'
      }
    }
  )

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`FalAI result fetch error: ${response.status} ${response.statusText} - ${errorText}`)
  }

  const data = await response.json()
  
  return {
    status: 'COMPLETED',
    video: data.video ? {
      url: data.video.url,
      content_type: data.video.content_type,
      width: data.video.width,
      height: data.video.height,
      fps: data.video.fps,
      duration: data.video.duration
    } : undefined,
    video_id: data.video_id
  }
}

