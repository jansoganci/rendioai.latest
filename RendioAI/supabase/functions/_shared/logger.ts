/**
 * Shared Logger Utility
 * 
 * Provides structured logging for all Edge Functions
 * 
 * Usage:
 *   import { logEvent } from '../_shared/logger.ts'
 *   logEvent('user_created', { user_id: '123' }, 'info')
 */

export function logEvent(
  eventType: string,
  data: Record<string, any>,
  level: 'info' | 'error' | 'warn' = 'info'
) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level,
    event: eventType,
    ...data,
    environment: Deno.env.get('ENVIRONMENT') || 'development'
  }
  
  console.log(JSON.stringify(logEntry))
}

