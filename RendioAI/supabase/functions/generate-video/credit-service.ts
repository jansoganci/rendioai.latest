/**
 * Credit Service
 * Handles credit deduction and refund operations
 */

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export interface CreditDeductionResult {
  success: boolean
  credits_remaining?: number
  error?: string
  current_credits?: number
}

export async function deductCredits(
  supabaseClient: SupabaseClient,
  user_id: string,
  amount: number
): Promise<{ data: CreditDeductionResult | null; error: any }> {
  return await supabaseClient.rpc('deduct_credits', {
    p_user_id: user_id,
    p_amount: amount,
    p_reason: 'video_generation'
  })
}

export async function refundCredits(
  supabaseClient: SupabaseClient,
  user_id: string,
  amount: number,
  reason: string = 'generation_failed_refund'
): Promise<{ error: any }> {
  return await supabaseClient.rpc('add_credits', {
    p_user_id: user_id,
    p_amount: amount,
    p_reason: reason,
    p_transaction_id: null
  })
}

