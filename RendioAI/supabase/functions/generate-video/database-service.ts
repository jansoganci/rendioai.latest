/**
 * Database Service
 * Handles all Supabase database queries
 */

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import type { ActiveModel, Theme, VideoJob } from './types.ts'

export async function fetchActiveModel(
  supabaseClient: SupabaseClient
): Promise<{ data: ActiveModel | null; error: any }> {
  return await supabaseClient
    .from('models')
    .select('id, cost_per_generation, provider, provider_model_id, is_available, pricing_type, base_price, required_fields')
    .eq('is_active', true)
    .eq('is_available', true)
    .single()
}

export async function fetchTheme(
  supabaseClient: SupabaseClient,
  theme_id: string
): Promise<{ data: Theme | null; error: any }> {
  return await supabaseClient
    .from('themes')
    .select('id, name, description, prompt, default_settings')
    .eq('id', theme_id)
    .eq('is_available', true)
    .single()
}

export async function createVideoJob(
  supabaseClient: SupabaseClient,
  user_id: string,
  model_id: string,
  prompt: string,
  settings: Record<string, any>,
  credits_used: number
): Promise<{ data: VideoJob | null; error: any }> {
  return await supabaseClient
    .from('video_jobs')
    .insert({
      user_id: user_id,
      model_id: model_id,
      prompt: prompt,
      settings: settings,
      status: 'pending',
      credits_used: credits_used
    })
    .select()
    .single()
}

export async function updateVideoJob(
  supabaseClient: SupabaseClient,
  job_id: string,
  updates: {
    provider_job_id?: string
    status?: string
    error_message?: string
  }
): Promise<{ error: any }> {
  return await supabaseClient
    .from('video_jobs')
    .update(updates)
    .eq('job_id', job_id)
}

