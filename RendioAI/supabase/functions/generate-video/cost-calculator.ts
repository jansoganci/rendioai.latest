/**
 * Cost Calculator
 * Handles dynamic cost calculation based on pricing models
 */

import type { ActiveModel, FinalSettings } from './types.ts'

export interface CostCalculationResult {
  costInDollars: number
  creditsToDeduct: number
  duration?: number
}

export function calculateCost(
  activeModel: ActiveModel,
  settings: FinalSettings | null,
  requiredFields: ActiveModel['required_fields']
): CostCalculationResult {
  let costInDollars: number
  let creditsToDeduct: number
  let duration: number | undefined

  if (activeModel.pricing_type === 'per_second') {
    duration = settings?.duration || 
               requiredFields?.settings?.duration?.default || 
               4
    costInDollars = (activeModel.base_price || 0) * duration
    // Convert dollars to credits: $0.1 = 1 credit
    // Example: $0.4 = 4 credits (multiply by 10)
    creditsToDeduct = Math.round(costInDollars * 10)
  } else if (activeModel.pricing_type === 'per_video') {
    costInDollars = activeModel.base_price || 0
    // Convert dollars to credits: $0.1 = 1 credit
    creditsToDeduct = Math.round(costInDollars * 10)
  } else {
    // Fallback: use cost_per_generation (already in credits)
    creditsToDeduct = activeModel.cost_per_generation || 0
    costInDollars = creditsToDeduct / 10  // Convert back to dollars for reporting
  }

  return {
    costInDollars,
    creditsToDeduct,
    duration
  }
}

