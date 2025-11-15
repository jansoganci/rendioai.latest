/**
 * Sentry Error Tracking Module
 * Provides centralized error tracking and monitoring for Edge Functions
 * 
 * Note: Sentry is optional - if SENTRY_DSN is not set, functions will still work
 * but errors won't be tracked in Sentry
 * 
 * For now, this is a stub implementation that logs to console.
 * To enable Sentry, configure SENTRY_DSN environment variable and update imports.
 */

// Stub implementation - logs to console instead of Sentry
// This allows deployment without Sentry dependency
const SENTRY_ENABLED = false // Set to true when SENTRY_DSN is configured

// Initialize Sentry - call this once in each Edge Function
export function initSentry(functionName: string) {
  const dsn = Deno.env.get('SENTRY_DSN')
  
  if (!dsn) {
    console.log(`[Sentry] SENTRY_DSN not configured, error tracking disabled for ${functionName}`)
    return
  }
  
  // TODO: When Sentry is needed, uncomment and configure:
  // import * as Sentry from 'https://esm.sh/@sentry/node@7.60.0'
  // Sentry.init({ dsn, environment: Deno.env.get('ENVIRONMENT') || 'development' })
  console.log(`[Sentry] Would initialize for ${functionName} (DSN configured but SDK not loaded)`)
}

// Capture exception with context
export function captureException(
  error: Error | unknown,
  context?: {
    user_id?: string
    job_id?: string
    action?: string
    metadata?: Record<string, any>
  }
) {
  const dsn = Deno.env.get('SENTRY_DSN')
  
  if (!dsn) {
    console.error('[Sentry] Error (not sent):', error, context)
    return
  }
  
  // Log error to console (Sentry SDK not loaded)
  console.error('[Sentry] Error (would send to Sentry):', {
    error: error instanceof Error ? error.message : String(error),
    stack: error instanceof Error ? error.stack : undefined,
    ...context
  })
}

// Capture message for non-error events
export function captureMessage(
  message: string,
  level: 'info' | 'warning' | 'error' = 'info',
  context?: Record<string, any>
) {
  const dsn = Deno.env.get('SENTRY_DSN')
  
  if (!dsn) {
    console.log(`[Sentry] ${level.toUpperCase()}: ${message}`, context)
    return
  }
  
  // Log to console (Sentry SDK not loaded)
  console.log(`[Sentry] ${level.toUpperCase()} (would send to Sentry): ${message}`, context)
}

// Performance monitoring
export function startTransaction(name: string, op: string = 'function') {
  if (!Deno.env.get('SENTRY_DSN')) {
    return null
  }
  
  // Return stub transaction object
  return {
    startChild: (options: any) => ({
      setStatus: (status: string) => {},
      finish: () => {}
    }),
    finish: () => {}
  }
}

// Measure async operation performance
export async function measurePerformance<T>(
  operation: string,
  fn: () => Promise<T>,
  metadata?: Record<string, any>
): Promise<T> {
  const startTime = Date.now()
  
  try {
    const result = await fn()
    const duration = Date.now() - startTime
    
    captureMessage(`Operation completed: ${operation}`, 'info', {
      duration_ms: duration,
      ...metadata,
    })
    
    return result
  } catch (error) {
    const duration = Date.now() - startTime
    
    captureException(error, {
      action: operation,
      metadata: {
        duration_ms: duration,
        ...metadata,
      },
    })
    
    throw error
  }
}

// Flush events before function terminates
export async function flush(timeout: number = 2000): Promise<boolean> {
  // No-op for stub implementation
  return true
}
