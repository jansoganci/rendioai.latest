/**
 * Provider Service
 * Handles AI provider API integration (FalAI, etc.)
 */

import type { ActiveModel, FinalSettings } from './types.ts'
import { submitFalAIJob } from '../_shared/falai-adapter.ts'

export async function submitProviderJob(
  activeModel: ActiveModel,
  prompt: string,
  image_url: string,
  finalSettings: FinalSettings
): Promise<{ request_id: string }> {
  if (activeModel.provider === 'fal') {
    const result = await submitFalAIJob(
      activeModel.provider_model_id,
      prompt,
      image_url,
      finalSettings
    )
    return { request_id: result.request_id }
  } else {
    throw new Error(`Provider ${activeModel.provider} not yet implemented`)
  }
}

