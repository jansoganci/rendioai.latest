/**
 * Request Validation Utilities
 */

import type { GenerateVideoRequest, ActiveModel } from './types.ts'

export function validateHttpMethod(method: string): Response | null {
  if (method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { 
        status: 405, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
  return null
}

export function validateIdempotencyKey(key: string | null): Response | null {
  if (!key) {
    return new Response(
      JSON.stringify({ error: 'Idempotency-Key header required' }),
      { 
        status: 400, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
  return null
}

export function validateRequiredFields(
  body: GenerateVideoRequest
): Response | null {
  const { user_id, theme_id, prompt } = body
  
  if (!user_id || !theme_id || !prompt) {
    return new Response(
      JSON.stringify({ error: 'Missing required fields: user_id, theme_id, prompt' }),
      { 
        status: 400, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
  return null
}

export function validateModelRequirements(
  activeModel: ActiveModel,
  prompt: string,
  image_url: string | undefined,
  settings: GenerateVideoRequest['settings']
): Response | null {
  const requiredFields = activeModel.required_fields || {}

  // Validate prompt
  if (requiredFields.requires_prompt && !prompt?.trim()) {
    return new Response(
      JSON.stringify({ error: 'prompt is required' }),
      { 
        status: 400, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }

  // Validate image_url
  if (requiredFields.requires_image && !image_url) {
    return new Response(
      JSON.stringify({ error: 'image_url is required for this model' }),
      { 
        status: 400, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }

  // Validate settings
  if (requiredFields.requires_settings && settings) {
    const settingsConfig = requiredFields.settings || {}
    
    if (settings.duration && settingsConfig.duration) {
      const allowedDurations = settingsConfig.duration.options || []
      if (!allowedDurations.includes(settings.duration)) {
        return new Response(
          JSON.stringify({ 
            error: `Invalid duration. Allowed values: ${allowedDurations.join(', ')}` 
          }),
          { 
            status: 400, 
            headers: { 'Content-Type': 'application/json' } 
          }
        )
      }
    }
    
    if (settings.aspect_ratio && settingsConfig.aspect_ratio) {
      const allowedAspectRatios = settingsConfig.aspect_ratio.options || []
      if (!allowedAspectRatios.includes(settings.aspect_ratio)) {
        return new Response(
          JSON.stringify({ 
            error: `Invalid aspect_ratio. Allowed values: ${allowedAspectRatios.join(', ')}` 
          }),
          { 
            status: 400, 
            headers: { 'Content-Type': 'application/json' } 
          }
        )
      }
    }
    
    if (settings.resolution && settingsConfig.resolution) {
      const allowedResolutions = settingsConfig.resolution.options || []
      if (!allowedResolutions.includes(settings.resolution)) {
        return new Response(
          JSON.stringify({ 
            error: `Invalid resolution. Allowed values: ${allowedResolutions.join(', ')}` 
          }),
          { 
            status: 400, 
            headers: { 'Content-Type': 'application/json' } 
          }
        )
      }
    }
  }

  return null
}

