/**
 * Generate Video Endpoint - Main Handler
 * Orchestrates the video generation workflow
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'

import type { GenerateVideoRequest, ActiveModel, FinalSettings } from './types.ts'
import { 
  validateHttpMethod, 
  validateIdempotencyKey, 
  validateRequiredFields, 
  validateModelRequirements 
} from './validators.ts'
import { checkIdempotency, storeIdempotencyRecord } from './idempotency-service.ts'
import { fetchActiveModel, fetchTheme, createVideoJob, updateVideoJob } from './database-service.ts'
import { calculateCost } from './cost-calculator.ts'
import { deductCredits, refundCredits } from './credit-service.ts'
import { submitProviderJob } from './provider-service.ts'

serve(async (req) => {
  console.log('[GENERATE-VIDEO] Request received:', req.method, req.url)
  
  try {
    // 1. Validate HTTP method
    console.log('[STEP 1] Validating HTTP method...')
    const methodError = validateHttpMethod(req.method)
    if (methodError) return methodError

    // 2. Validate idempotency key
    console.log('[STEP 2] Checking idempotency key...')
    const idempotencyKey = req.headers.get('Idempotency-Key')
    console.log('[STEP 2] Idempotency key:', idempotencyKey ? 'present' : 'missing')
    
    const keyError = validateIdempotencyKey(idempotencyKey)
    if (keyError) {
      logEvent('generate_video_missing_idempotency_key', {}, 'warn')
      return keyError
    }

    // 3. Parse and validate request body
    console.log('[STEP 3] Parsing request body...')
    let body: GenerateVideoRequest
    try {
      body = await req.json()
    } catch (jsonError) {
      console.error('[STEP 3] JSON parsing error:', jsonError.message)
      logEvent('generate_video_invalid_json', { 
        error: jsonError.message 
      }, 'error')
      return new Response(
        JSON.stringify({ 
          error: 'Invalid JSON in request body',
          details: jsonError.message 
        }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }
    const { user_id, theme_id, prompt, image_url, settings } = body
    console.log('[STEP 3] Request data:', { 
      user_id, 
      theme_id, 
      prompt_length: prompt?.length,
      has_image_url: !!image_url,
      settings 
    })
    
    console.log('[STEP 4] Validating required fields...')
    const fieldsError = validateRequiredFields(body)
    if (fieldsError) {
      logEvent('generate_video_missing_fields', { 
        has_user_id: !!user_id,
        has_theme_id: !!theme_id,
        has_prompt: !!prompt 
      }, 'warn')
      return fieldsError
    }

    // 4. Initialize Supabase client
    console.log('[STEP 5] Initializing Supabase client...')
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 5. Check idempotency
    console.log('[STEP 6] Checking idempotency log...')
    const idempotencyResult = await checkIdempotency(supabaseClient, idempotencyKey!, user_id)
    if (idempotencyResult.isDuplicate) {
      console.log('[STEP 6] Idempotent request detected - returning cached response')
      console.log('[STEP 6] Existing job_id:', idempotencyResult.cachedResponse?.job_id)
      logEvent('idempotent_replay', { 
        user_id, 
        idempotency_key: idempotencyKey,
        job_id: idempotencyResult.cachedResponse?.job_id
      })
      return new Response(
        JSON.stringify(idempotencyResult.cachedResponse),
        {
          status: idempotencyResult.statusCode || 200,
          headers: {
            'Content-Type': 'application/json',
            'X-Idempotent-Replay': 'true'
          }
        }
      )
    }

    // 6. Fetch active model
    console.log('[STEP 7] Fetching active model from database...')
    const { data: activeModel, error: modelError } = await fetchActiveModel(supabaseClient)
    console.log('[STEP 7] Active model fetch result:', { 
      found: !!activeModel, 
      error: modelError?.message,
      model_id: activeModel?.id,
      provider: activeModel?.provider,
      provider_model_id: activeModel?.provider_model_id,
      pricing_type: activeModel?.pricing_type,
      base_price: activeModel?.base_price
    })

    if (modelError || !activeModel) {
      console.log('[STEP 7] ERROR: No active model found')
      logEvent('generate_video_no_active_model', { error: modelError?.message }, 'error')
      return new Response(
        JSON.stringify({ error: 'No active model found. Please contact support.' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 7. Fetch theme
    console.log('[STEP 8] Fetching theme from database...')
    const { data: theme, error: themeError } = await fetchTheme(supabaseClient, theme_id)
    console.log('[STEP 8] Theme fetch result:', { 
      found: !!theme, 
      error: themeError?.message,
      theme_id: theme_id,
      theme_name: theme?.name
    })

    if (themeError || !theme) {
      console.log('[STEP 8] ERROR: Theme not found')
      logEvent('generate_video_theme_not_found', { theme_id, error: themeError?.message }, 'error')
      return new Response(
        JSON.stringify({ error: 'Theme not found or not available' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log('[STEP 8] Theme found:', { 
      name: theme.name,
      has_default_settings: !!theme.default_settings,
      note: 'Using user\'s prompt from request (may be modified from theme default)'
    })

    // 8. Validate model requirements
    console.log('[STEP 9] Validating required fields based on model requirements...')
    const requiredFields = activeModel.required_fields || {}
    console.log('[STEP 9] Model required_fields:', {
      requires_prompt: requiredFields.requires_prompt,
      requires_image: requiredFields.requires_image,
      requires_settings: requiredFields.requires_settings
    })

    const validationError = validateModelRequirements(activeModel, prompt, image_url, settings)
    if (validationError) {
      console.log('[STEP 9] Validation failed')
      return validationError
    }
    console.log('[STEP 9] Validation passed')

    // 9. Build final settings and calculate cost
    console.log('[STEP 10] Building final settings and calculating cost...')
    const settingsConfig = requiredFields.settings || {}
    const duration = settings?.duration || settingsConfig.duration?.default || 4
    
    const finalSettings: FinalSettings = {
      resolution: (settings?.resolution || settingsConfig.resolution?.default || 'auto') as 'auto' | '720p',
      aspect_ratio: (settings?.aspect_ratio || settingsConfig.aspect_ratio?.default || 'auto') as 'auto' | '9:16' | '16:9',
      duration: duration as 4 | 8 | 12
    }
    
    console.log('[STEP 10] Final settings:', {
      resolution: finalSettings.resolution,
      aspect_ratio: finalSettings.aspect_ratio,
      duration: finalSettings.duration,
      note: 'User settings override model defaults'
    })

    console.log('[STEP 10] Calculating cost dynamically...')
    console.log('[STEP 10] Pricing type:', activeModel.pricing_type)
    console.log('[STEP 10] Base price:', activeModel.base_price)
    
    const costResult = calculateCost(activeModel, finalSettings, requiredFields)
    
    console.log('[STEP 10] Final cost:', {
      cost_in_dollars: costResult.costInDollars,
      credits_to_deduct: costResult.creditsToDeduct,
      duration: costResult.duration,
      pricing_type: activeModel.pricing_type
    })

    // 10. Deduct credits
    console.log('[STEP 11] Deducting credits...')
    console.log('[STEP 11] Amount to deduct:', costResult.creditsToDeduct, 'credits')
    const { data: deductResult, error: deductError } = await deductCredits(
      supabaseClient,
      user_id,
      costResult.creditsToDeduct
    )

    console.log('[STEP 11] Credit deduction result:', { 
      success: deductResult?.success, 
      credits_remaining: deductResult?.credits_remaining,
      error: deductError?.message || deductResult?.error 
    })

    if (deductError || !deductResult?.success) {
      logEvent('generate_video_insufficient_credits', { 
        user_id,
        model_id: activeModel.id,
        cost: costResult.creditsToDeduct,
        error: deductError?.message || deductResult?.error
      }, 'warn')
      return new Response(
        JSON.stringify({ 
          error: deductResult?.error || 'Insufficient credits',
          credits_remaining: deductResult?.current_credits || 0
        }),
        { status: 402, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 11. Create video job
    console.log('[STEP 12] Creating video job in database...')
    const { data: job, error: jobError } = await createVideoJob(
      supabaseClient,
      user_id,
      activeModel.id,
      prompt,
      settings || {},
      costResult.creditsToDeduct
    )

    console.log('[STEP 12] Job creation result:', { 
      job_id: job?.job_id, 
      error: jobError?.message 
    })

    if (jobError) {
      console.log('[STEP 12] ERROR: Job creation failed, refunding credits...')
      await refundCredits(supabaseClient, user_id, costResult.creditsToDeduct)
      logEvent('generate_video_job_creation_failed', { user_id, error: jobError.message }, 'error')
      return new Response(
        JSON.stringify({ error: 'Failed to create job' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 12. Submit to provider
    console.log('[STEP 13] Calling FalAI API...')
    console.log('[STEP 13] Using model:', activeModel.provider_model_id)
    console.log('[STEP 13] Using user\'s prompt (may be modified from theme default)')
    console.log('[STEP 13] Image URL:', image_url ? 'provided' : 'missing')
    
    try {
      if (!image_url && activeModel.required_fields?.requires_image) {
        throw new Error('image_url is required for this model')
      }

      console.log('[STEP 13] Submitting FalAI job with final settings:', finalSettings)
      const providerResult = await submitProviderJob(
        activeModel,
        prompt,
        image_url!,
        finalSettings
      )

      console.log('[STEP 13] FalAI job submitted successfully, provider_job_id:', providerResult.request_id)

      // 14. Update job with provider_job_id
      console.log('[STEP 14] Updating job with provider_job_id...')
      await updateVideoJob(supabaseClient, job!.job_id, {
        provider_job_id: providerResult.request_id,
        status: 'processing'
      })
      console.log('[STEP 14] Job updated to processing status')

      logEvent('falai_job_submitted', {
        user_id,
        job_id: job!.job_id,
        provider_job_id: providerResult.request_id,
        model_id: activeModel.provider_model_id,
        settings: finalSettings
      })
    } catch (providerError) {
      console.log('[STEP 13] ERROR: FalAI API call failed:', providerError.message)
      
      await updateVideoJob(supabaseClient, job!.job_id, {
        status: 'failed',
        error_message: providerError.message
      })
      await refundCredits(supabaseClient, user_id, costResult.creditsToDeduct)
      
      logEvent('generate_video_provider_error', { 
        user_id,
        job_id: job!.job_id,
        error: providerError.message 
      }, 'error')
      
      return new Response(
        JSON.stringify({ 
          error: 'Failed to start video generation',
          details: providerError.message
        }),
        { status: 502, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 15. Store idempotency record
    console.log('[STEP 15] Storing idempotency record...')
    const responseBody = {
      job_id: job!.job_id,
      status: 'pending',
      credits_used: costResult.creditsToDeduct
    }

    await storeIdempotencyRecord(
      supabaseClient,
      idempotencyKey!,
      user_id,
      job!.job_id,
      responseBody
    )
    console.log('[STEP 15] Idempotency record stored')

    logEvent('video_generation_started', {
      user_id,
      job_id: job!.job_id,
      model_id: activeModel.id,
      provider: activeModel.provider,
      credits_used: costResult.creditsToDeduct,
      pricing_type: activeModel.pricing_type,
      duration: costResult.duration
    })

    console.log('[SUCCESS] Video generation started successfully')
    console.log('[SUCCESS] Response:', responseBody)
    return new Response(
      JSON.stringify(responseBody),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[ERROR] Unexpected error in generate-video:', error)
    console.error('[ERROR] Error message:', error.message)
    console.error('[ERROR] Error stack:', error.stack)
    logEvent('video_generation_error', { 
      error: error.message,
      stack: error.stack 
    }, 'error')
    
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
