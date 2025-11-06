/**
 * Types and Interfaces for Generate Video Endpoint
 */

export interface GenerateVideoRequest {
  user_id: string
  theme_id: string
  prompt: string
  image_url?: string
  settings?: {
    resolution?: 'auto' | '720p'
    aspect_ratio?: 'auto' | '9:16' | '16:9'
    duration?: 4 | 8 | 12
  }
}

export interface ActiveModel {
  id: string
  cost_per_generation: number
  provider: string
  provider_model_id: string
  is_available: boolean
  pricing_type: 'per_second' | 'per_video' | null
  base_price: number | null
  required_fields: {
    requires_prompt?: boolean
    requires_image?: boolean
    requires_settings?: boolean
    settings?: {
      resolution?: { default?: string; options?: string[] }
      aspect_ratio?: { default?: string; options?: string[] }
      duration?: { default?: number; options?: number[] }
    }
  } | null
}

export interface Theme {
  id: string
  name: string
  description: string | null
  prompt: string
  default_settings: Record<string, any> | null
}

export interface FinalSettings {
  resolution: 'auto' | '720p'
  aspect_ratio: 'auto' | '9:16' | '16:9'
  duration: 4 | 8 | 12
}

export interface VideoJob {
  job_id: string
  user_id: string
  model_id: string
  prompt: string
  settings: Record<string, any>
  status: string
  credits_used: number
}

