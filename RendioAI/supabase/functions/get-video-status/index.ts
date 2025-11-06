/**
 * Get Video Status Endpoint
 * 
 * Polls video generation progress and updates job status in database.
 * Checks FalAI queue status and updates job when completed.
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { logEvent } from '../_shared/logger.ts'
import { checkFalAIStatus, getFalAIResult } from '../_shared/falai-adapter.ts'

serve(async (req) => {
  try {
    // 1. Validate HTTP method
    if (req.method !== 'GET') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { 
          status: 405, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 2. Get job_id from query params
    const url = new URL(req.url)
    const job_id = url.searchParams.get('job_id')
    
    if (!job_id) {
      logEvent('get_video_status_missing_job_id', {}, 'warn')
      return new Response(
        JSON.stringify({ error: 'job_id query parameter required' }),
        { 
          status: 400, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 3. Get job from database
    const { data: job, error: jobError } = await supabaseClient
      .from('video_jobs')
      .select(`
        job_id,
        user_id,
        model_id,
        prompt,
        status,
        video_url,
        thumbnail_url,
        credits_used,
        provider_job_id,
        error_message,
        created_at,
        completed_at,
        models!inner(provider_model_id, provider, name)
      `)
      .eq('job_id', job_id)
      .single()

    if (jobError || !job) {
      logEvent('get_video_status_job_not_found', { 
        job_id,
        error: jobError?.message 
      }, 'warn')
      return new Response(
        JSON.stringify({ error: 'Job not found' }),
        { 
          status: 404, 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 4. If job is already completed or failed, return current status with full job details
    if (job.status === 'completed' || job.status === 'failed') {
      // Get model name from joined models table
      const model = job.models as any
      
      return new Response(
        JSON.stringify({
          job_id: job.job_id,
          status: job.status,
          prompt: job.prompt,
          model_name: model?.name || '',
          credits_used: job.credits_used,
          video_url: job.video_url,
          thumbnail_url: job.thumbnail_url,
          error_message: job.error_message,
          created_at: job.created_at
        }),
        { 
          headers: { 'Content-Type': 'application/json' } 
        }
      )
    }

    // 5. If still pending/processing, check FalAI status
    if (job.status === 'pending' || job.status === 'processing') {
      if (!job.provider_job_id) {
        logEvent('get_video_status_no_provider_job_id', { job_id }, 'warn')
        
        // Get model name from joined models table
        const modelForNoProvider = job.models as any
        
        return new Response(
          JSON.stringify({
            job_id: job.job_id,
            status: job.status,
            prompt: job.prompt,
            model_name: modelForNoProvider?.name || '',
            credits_used: job.credits_used,
            video_url: null,
            thumbnail_url: null,
            created_at: job.created_at
          }),
          { 
            headers: { 'Content-Type': 'application/json' } 
          }
        )
      }

      try {
        const model = job.models as any
        const providerStatus = await checkFalAIStatus(
          model.provider_model_id,
          job.provider_job_id
        )

        logEvent('falai_status_check', {
          job_id,
          provider_job_id: job.provider_job_id,
          falai_status: providerStatus.status
        })

        // 6. Handle completed status
        if (providerStatus.status === 'COMPLETED') {
          // Strategy: Try multiple methods to get the video URL
          // 1. Check if video URL is already in providerStatus (from checkFalAIStatus)
          // 2. If response_url exists, fetch directly from it (most reliable)
          // 3. Fall back to getFalAIResult with constructed URL
          
          let videoUrl = providerStatus.video?.url
          let result: any = null
          
          // If not found, try fetching from response_url first (most reliable)
          if (!videoUrl && providerStatus.response_url) {
            try {
              const apiKey = Deno.env.get('FALAI_API_KEY')
              if (apiKey) {
                const responseUrlResponse = await fetch(providerStatus.response_url, {
                  method: 'GET',
                  headers: {
                    'Authorization': `Key ${apiKey}`,
                    'Content-Type': 'application/json'
                  }
                })
                
                if (responseUrlResponse.ok) {
                  const responseUrlData = await responseUrlResponse.json()
                  videoUrl = responseUrlData.video?.url
                  if (videoUrl) {
                    result = {
                      video: responseUrlData.video,
                      video_id: responseUrlData.video_id
                    }
                  }
                }
              }
            } catch (responseUrlError: any) {
              console.error('[get-video-status] Error fetching from response_url:', responseUrlError.message)
            }
          }
          
          // If still not found, try getFalAIResult (fallback)
          if (!videoUrl) {
            try {
              result = await getFalAIResult(
                model.provider_model_id,
                job.provider_job_id
              )

              videoUrl = result.video?.url
            } catch (resultError: any) {
              console.error('[get-video-status] Error calling getFalAIResult:', resultError.message)
              
              logEvent('get_falai_result_error', {
                job_id,
                provider_job_id: job.provider_job_id,
                error: resultError.message
              }, 'error')
            }
          }

          if (videoUrl) {
            // Update job in database with video URL
            const { error: updateError } = await supabaseClient
              .from('video_jobs')
              .update({
                status: 'completed',
                video_url: videoUrl,
                thumbnail_url: null, // Skip thumbnails for Phase 2
                completed_at: new Date().toISOString()
              })
              .eq('job_id', job_id)

            if (updateError) {
              console.error('[get-video-status] Database update error:', updateError.message)
              logEvent('get_video_status_update_error', { 
                job_id,
                error: updateError.message 
              }, 'error')
              // Continue anyway - return the video URL
            }

            logEvent('video_generation_completed', {
              job_id,
              provider_job_id: job.provider_job_id,
              video_url: videoUrl
            })

            // Get model name from joined models table
            const modelForResponse = job.models as any

            return new Response(
              JSON.stringify({
                job_id: job.job_id,
                status: 'completed',
                prompt: job.prompt,
                model_name: modelForResponse?.name || '',
                credits_used: job.credits_used,
                video_url: videoUrl,
                thumbnail_url: null,
                created_at: job.created_at
              }),
              { 
                headers: { 'Content-Type': 'application/json' } 
              }
            )
          } else {
            console.error('[get-video-status] Video URL not found after COMPLETED status', {
              job_id,
              provider_job_id: job.provider_job_id
            })
            
            logEvent('video_url_missing_after_completion', {
              job_id,
              provider_job_id: job.provider_job_id
            }, 'error')
            
            // Don't update status - keep it as processing so we can retry
            // The next poll might find the video URL
          }
        }

        // 7. Handle failed status
        if (providerStatus.status === 'FAILED') {
          const { error: updateError } = await supabaseClient
            .from('video_jobs')
            .update({
              status: 'failed',
              error_message: providerStatus.error || 'Video generation failed'
            })
            .eq('job_id', job_id)

          if (updateError) {
            logEvent('get_video_status_failed_update_error', { 
              job_id,
              error: updateError.message 
            }, 'error')
          }

          logEvent('video_generation_failed', {
            job_id,
            provider_job_id: job.provider_job_id,
            error: providerStatus.error
          })

          // Note: Credits already deducted, but we could refund here if needed
          // For now, we'll handle refunds in Phase 6 (retry logic)

          // Get model name from joined models table
          const modelForFailed = job.models as any

          return new Response(
            JSON.stringify({
              job_id: job.job_id,
              status: 'failed',
              prompt: job.prompt,
              model_name: modelForFailed?.name || '',
              credits_used: job.credits_used,
              video_url: null,
              thumbnail_url: null,
              error_message: providerStatus.error || 'Video generation failed',
              created_at: job.created_at
            }),
            { 
              headers: { 'Content-Type': 'application/json' } 
            }
          )
        }

        // 8. Update status to "processing" if it's in progress
        if (providerStatus.status === 'IN_PROGRESS' && job.status === 'pending') {
          await supabaseClient
            .from('video_jobs')
            .update({ status: 'processing' })
            .eq('job_id', job_id)
        }

        // 9. Return current status (IN_PROGRESS or IN_QUEUE) with full job details
        // Get model name from joined models table
        const modelForStatus = job.models as any

        return new Response(
          JSON.stringify({
            job_id: job.job_id,
            status: job.status === 'pending' && providerStatus.status === 'IN_PROGRESS' ? 'processing' : job.status,
            prompt: job.prompt,
            model_name: modelForStatus?.name || '',
            credits_used: job.credits_used,
            video_url: job.video_url,
            thumbnail_url: job.thumbnail_url,
            created_at: job.created_at
          }),
          { 
            headers: { 'Content-Type': 'application/json' } 
          }
        )

      } catch (providerError) {
        // If provider check fails, return current DB status
        logEvent('get_video_status_provider_check_failed', { 
          job_id,
          provider_job_id: job.provider_job_id,
          error: providerError.message 
        }, 'error')
        
        // Don't fail the request - return current status
        // Get model name from joined models table
        const modelForError = job.models as any
        
        return new Response(
          JSON.stringify({
            job_id: job.job_id,
            status: job.status,
            prompt: job.prompt,
            model_name: modelForError?.name || '',
            credits_used: job.credits_used,
            video_url: job.video_url,
            thumbnail_url: job.thumbnail_url,
            created_at: job.created_at
          }),
          { 
            headers: { 'Content-Type': 'application/json' } 
          }
        )
      }
    }

    // 9. Return current status
    return new Response(
      JSON.stringify({
        job_id: job.job_id,
        status: job.status,
        video_url: job.video_url,
        thumbnail_url: job.thumbnail_url
      }),
      { 
        headers: { 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    logEvent('get_video_status_error', { 
      error: error.message,
      stack: error.stack 
    }, 'error')
    
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )
  }
})

