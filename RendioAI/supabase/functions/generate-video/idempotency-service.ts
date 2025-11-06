/**
 * Idempotency Service
 * Handles duplicate request detection and caching
 */

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export interface IdempotencyResult {
  isDuplicate: boolean
  cachedResponse?: {
    job_id: string
    status: string
    credits_used: number
  }
  statusCode?: number
}

export async function checkIdempotency(
  supabaseClient: SupabaseClient,
  idempotencyKey: string,
  user_id: string
): Promise<IdempotencyResult> {
  const { data: existing } = await supabaseClient
    .from('idempotency_log')
    .select('job_id, response_data, status_code')
    .eq('idempotency_key', idempotencyKey)
    .eq('user_id', user_id)
    .gt('expires_at', new Date().toISOString())
    .maybeSingle()

  if (existing) {
    return {
      isDuplicate: true,
      cachedResponse: existing.response_data as any,
      statusCode: existing.status_code
    }
  }

  return { isDuplicate: false }
}

export async function storeIdempotencyRecord(
  supabaseClient: SupabaseClient,
  idempotencyKey: string,
  user_id: string,
  job_id: string,
  responseData: any,
  statusCode: number = 200
): Promise<void> {
  await supabaseClient.from('idempotency_log').insert({
    idempotency_key: idempotencyKey,
    user_id: user_id,
    job_id: job_id,
    operation_type: 'video_generation',
    response_data: responseData,
    status_code: statusCode
  })
}

