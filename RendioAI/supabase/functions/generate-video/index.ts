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
import { refundCredits } from './credit-service.ts'
import { submitProviderJob } from './provider-service.ts'

// Phase 5 Debug Helpers (toggle via env DEBUG_PHASE5=true)
const DEBUG_PHASE5 = Deno.env.get('DEBUG_PHASE5') === 'true'
function p5log(...args: any[]) { if (DEBUG_PHASE5) console.log(...args) }
function p5time(label: string) { const t = Date.now(); return () => Date.now() - t }
function truncate(s: string, max = 120) { return s.length > max ? s.substring(0, max) + '...' : s }

serve(async (req) => {
  const tAll = p5time('generate')
  const requestId = crypto.randomUUID()
  console.log('[GENERATE-VIDEO] Request received:', req.method, req.url)

  try {
    // STEP A: Entry
    p5log('[P5][GenerateVideo][ENTRY]', { path: new URL(req.url).pathname, requestId })

    // 1. Validate HTTP method
    console.log('[STEP 1] Validating HTTP method...')
    const methodError = validateHttpMethod(req.method)
    if (methodError) {
      p5log('[P5][GenerateVideo][ERR]', { step: 'method_validation', requestId })
      return methodError
    }

    // 2. Validate idempotency key
    console.log('[STEP 2] Checking idempotency key...')
    const idempotencyKey = req.headers.get('Idempotency-Key')
    console.log('[STEP 2] Idempotency key:', idempotencyKey ? 'present' : 'missing')

    const keyError = validateIdempotencyKey(idempotencyKey)
    if (keyError) {
      p5log('[P5][GenerateVideo][ERR]', { step: 'idempotency_validation', requestId })
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

    // STEP B: Auth/Parse
    p5log('[P5][GenerateVideo][AUTH]', {
      user_id,
      hasAuth: !!user_id,
      theme_id,
      promptLen: prompt?.length || 0,
      requestId
    })

    console.log('[STEP 4] Validating required fields...')
    const fieldsError = validateRequiredFields(body)
    if (fieldsError) {
      p5log('[P5][GenerateVideo][ERR]', { step: 'field_validation', requestId })
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
    // STEP C: Idempotency check
    p5log('[P5][GenerateVideo][IdemCheck][START]', { idempotencyKey, user_id, requestId })
    console.log('[STEP 6] Checking idempotency log...')
    const idempotencyResult = await checkIdempotency(supabaseClient, idempotencyKey!, user_id)
    p5log('[P5][GenerateVideo][IdemCheck][RESULT]', {
      hit: idempotencyResult.isDuplicate,
      job_id: idempotencyResult.cachedResponse?.job_id,
      requestId
    })
    if (idempotencyResult.isDuplicate) {
      console.log('[STEP 6] Idempotent request detected - returning cached response')
      console.log('[STEP 6] Existing job_id:', idempotencyResult.cachedResponse?.job_id)
      logEvent('idempotent_replay', {
        user_id,
        idempotency_key: idempotencyKey,
        job_id: idempotencyResult.cachedResponse?.job_id
      })
      p5log('[P5][GenerateVideo][EXIT]', { reason: 'idempotent_replay', totalMs: tAll(), requestId })
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
      p5log('[P5][GenerateVideo][ERR]', { step: 'model_fetch', error: modelError?.message, requestId })
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
      p5log('[P5][GenerateVideo][ERR]', { step: 'theme_fetch', theme_id, error: themeError?.message, requestId })
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
      p5log('[P5][GenerateVideo][ERR]', { step: 'model_requirements', requestId })
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

    // STEP D: Cost calc / model lookup
    p5log('[P5][GenerateVideo][Cost][CALC]', {
      model_id: activeModel.id,
      pricing_type: activeModel.pricing_type,
      credits: costResult.creditsToDeduct,
      duration: costResult.duration,
      requestId
    })

    console.log('[STEP 10] Final cost:', {
      cost_in_dollars: costResult.costInDollars,
      credits_to_deduct: costResult.creditsToDeduct,
      duration: costResult.duration,
      pricing_type: activeModel.pricing_type
    })

    // 10. Atomically deduct credits and create job
    // STEP E: Atomic RPC call
    const tAtomic = p5time('atomic')
    p5log('[P5][GenerateVideo][Atomic][CALL]', {
      user_id,
      model_id: activeModel.id,
      idempotencyKey,
      requestId
    })
    console.log('[STEP 11] Calling atomic generate_video_atomic procedure...')
    console.log('[STEP 11] Amount to deduct:', costResult.creditsToDeduct, 'credits')

    const { data: atomicResult, error: atomicError } = await supabaseClient.rpc('generate_video_atomic', {
      p_user_id: user_id,
      p_model_id: activeModel.id,
      p_prompt: prompt,
      p_settings: settings || {},
      p_idempotency_key: idempotencyKey
    })

    console.log('[STEP 11] Atomic operation result:', {
      job_id: atomicResult?.job_id,
      credits_used: atomicResult?.credits_used,
      status: atomicResult?.status,
      error: atomicError?.message
    })

    if (atomicError) {
      p5log('[P5][GenerateVideo][Atomic][ERR]', {
        code: atomicError?.code,
        msg: truncate(atomicError?.message || '', 120),
        requestId
      })
      // Check if it's an insufficient credits error
      if (atomicError.code === 'P0001') {
        logEvent('generate_video_insufficient_credits', {
          user_id,
          model_id: activeModel.id,
          cost: costResult.creditsToDeduct,
          error: atomicError.message
        }, 'warn')
        return new Response(
          JSON.stringify({
            error: 'Insufficient credits',
            credits_remaining: 0
          }),
          { status: 402, headers: { 'Content-Type': 'application/json' } }
        )
      }

      // Other database errors
      logEvent('generate_video_atomic_error', {
        user_id,
        error: atomicError.message
      }, 'error')
      return new Response(
        JSON.stringify({ error: atomicError.message }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    p5log('[P5][GenerateVideo][Atomic][OK]', {
      job_id: atomicResult?.job_id,
      ms: tAtomic(),
      requestId
    })
    console.log('[STEP 11] Atomic operation successful - credits deducted and job created')

    // Extract job_id from atomic result
    const job = { job_id: atomicResult.job_id }

    // 12. Submit to provider
    // STEP F: Provider submit
    const tProvider = p5time('provider')
    p5log('[P5][GenerateVideo][Provider][CALL]', {
      provider: activeModel.provider,
      model: activeModel.provider_model_id,
      job_id: job!.job_id,
      requestId
    })
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

      p5log('[P5][GenerateVideo][Provider][OK]', {
        provider_job_id: providerResult.request_id,
        ms: tProvider(),
        requestId
      })
      console.log('[STEP 13] FalAI job submitted successfully, provider_job_id:', providerResult.request_id)

      // 14. Update job with provider_job_id
      // STEP G: Job update (pending -> processing)
      p5log('[P5][GenerateVideo][JobUpdate][CALL]', {
        job_id: job!.job_id,
        status: 'pending->processing',
        requestId
      })
      console.log('[STEP 14] Updating job with provider_job_id...')
      await updateVideoJob(supabaseClient, job!.job_id, {
        provider_job_id: providerResult.request_id,
        status: 'processing'
      })
      p5log('[P5][GenerateVideo][JobUpdate][OK]', { job_id: job!.job_id, requestId })
      console.log('[STEP 14] Job updated to processing status')

      logEvent('falai_job_submitted', {
        user_id,
        job_id: job!.job_id,
        provider_job_id: providerResult.request_id,
        model_id: activeModel.provider_model_id,
        settings: finalSettings
      })
    } catch (providerError) {
      p5log('[P5][GenerateVideo][Provider][ERR]', {
        msg: truncate(providerError.message, 120),
        ms: tProvider(),
        requestId
      })
      console.log('[STEP 13] ERROR: FalAI API call failed:', providerError.message)

      // STEP G: Job update (pending -> failed)
      p5log('[P5][GenerateVideo][JobUpdate][CALL]', {
        job_id: job!.job_id,
        status: 'pending->failed',
        requestId
      })
      // Update job status to failed
      await updateVideoJob(supabaseClient, job!.job_id, {
        status: 'failed',
        error_message: providerError.message
      })

      // Refund credits since provider failed after successful atomic operation
      p5log('[P5][GenerateVideo][Refund][CALL]', {
        user_id,
        amount: costResult.creditsToDeduct,
        requestId
      })
      const refundResult = await refundCredits(supabaseClient, user_id, costResult.creditsToDeduct)
      p5log('[P5][GenerateVideo][Refund][RESULT]', {
        error: refundResult.error ? truncate(refundResult.error.message, 120) : null,
        requestId
      })

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

    // 15. Build response (idempotency record already stored by atomic procedure)
    console.log('[STEP 15] Building response...')
    const responseBody = {
      job_id: job!.job_id,
      status: 'pending',
      credits_used: costResult.creditsToDeduct
    }
    console.log('[STEP 15] Note: Idempotency record was stored atomically in STEP 11')

    logEvent('video_generation_started', {
      user_id,
      job_id: job!.job_id,
      model_id: activeModel.id,
      provider: activeModel.provider,
      credits_used: costResult.creditsToDeduct,
      pricing_type: activeModel.pricing_type,
      duration: costResult.duration
    })

    // STEP H: Exit
    p5log('[P5][GenerateVideo][EXIT]', {
      job_id: job!.job_id,
      totalMs: tAll(),
      requestId
    })
    console.log('[SUCCESS] Video generation started successfully')
    console.log('[SUCCESS] Response:', responseBody)
    return new Response(
      JSON.stringify(responseBody),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    p5log('[P5][GenerateVideo][ERR]', {
      step: 'uncaught_exception',
      msg: truncate(error.message, 120),
      requestId
    })
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
