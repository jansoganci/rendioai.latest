/**
 * Structured Logging Module
 * Provides consistent logging with integration to Sentry and Telegram
 */

import { captureMessage } from './sentry.ts'
import { alertInfo, AlertLevel, sendAlert } from './telegram.ts'

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  CRITICAL = 4,
}

interface LogContext {
  function?: string
  user_id?: string
  job_id?: string
  duration_ms?: number
  metadata?: Record<string, any>
}

interface LogEntry {
  timestamp: string
  level: LogLevel
  message: string
  context?: LogContext
  error?: {
    message: string
    stack?: string
  }
}

class StructuredLogger {
  private functionName: string
  private minLevel: LogLevel

  constructor(functionName: string) {
    this.functionName = functionName
    const envLevel = Deno.env.get('LOG_LEVEL') || 'INFO'
    this.minLevel = LogLevel[envLevel as keyof typeof LogLevel] || LogLevel.INFO
  }

  /**
   * Format log entry for console output
   */
  private formatLog(entry: LogEntry): string {
    const levelStr = LogLevel[entry.level]
    const prefix = `[${entry.timestamp}] [${levelStr}] [${this.functionName}]`

    let message = `${prefix} ${entry.message}`

    if (entry.context) {
      const contextStr = Object.entries(entry.context)
        .filter(([_, v]) => v !== undefined)
        .map(([k, v]) => `${k}=${JSON.stringify(v)}`)
        .join(' ')
      if (contextStr) {
        message += ` | ${contextStr}`
      }
    }

    if (entry.error) {
      message += ` | error="${entry.error.message}"`
      if (entry.error.stack) {
        message += `\n${entry.error.stack}`
      }
    }

    return message
  }

  /**
   * Create log entry
   */
  private createEntry(
    level: LogLevel,
    message: string,
    context?: LogContext,
    error?: Error
  ): LogEntry {
    return {
      timestamp: new Date().toISOString(),
      level,
      message,
      context: {
        ...context,
        function: this.functionName,
      },
      error: error ? {
        message: error.message,
        stack: error.stack,
      } : undefined,
    }
  }

  /**
   * Log to console and external services
   */
  private async log(
    level: LogLevel,
    message: string,
    context?: LogContext,
    error?: Error
  ) {
    if (level < this.minLevel) {
      return
    }

    const entry = this.createEntry(level, message, context, error)

    // Always log to console
    console.log(this.formatLog(entry))

    // Send to Sentry for WARN and above
    if (level >= LogLevel.WARN) {
      const sentryLevel = level === LogLevel.WARN ? 'warning' : 'error'
      captureMessage(message, sentryLevel, {
        ...context,
        error: error?.message,
      })
    }

    // Send critical alerts to Telegram
    if (level === LogLevel.CRITICAL) {
      await sendAlert(
        AlertLevel.CRITICAL,
        'Critical Error',
        message,
        {
          function: this.functionName,
          ...context,
          error: error?.message,
        }
      )
    }
  }

  // Public logging methods
  debug(message: string, context?: LogContext) {
    this.log(LogLevel.DEBUG, message, context)
  }

  info(message: string, context?: LogContext) {
    this.log(LogLevel.INFO, message, context)
  }

  warn(message: string, context?: LogContext) {
    this.log(LogLevel.WARN, message, context)
  }

  error(message: string, error?: Error, context?: LogContext) {
    this.log(LogLevel.ERROR, message, context, error)
  }

  critical(message: string, error?: Error, context?: LogContext) {
    this.log(LogLevel.CRITICAL, message, context, error)
  }

  /**
   * Log operation timing
   */
  async time<T>(
    operation: string,
    fn: () => Promise<T>,
    context?: LogContext
  ): Promise<T> {
    const startTime = Date.now()
    this.info(`Starting ${operation}`, context)

    try {
      const result = await fn()
      const duration = Date.now() - startTime

      this.info(`Completed ${operation}`, {
        ...context,
        duration_ms: duration,
      })

      return result
    } catch (error) {
      const duration = Date.now() - startTime

      this.error(
        `Failed ${operation}`,
        error as Error,
        {
          ...context,
          duration_ms: duration,
        }
      )

      throw error
    }
  }
}

// Specialized loggers for common events

/**
 * Log video migration events
 */
export function logVideoMigration(
  logger: StructuredLogger,
  jobId: string,
  userId: string,
  success: boolean,
  duration: number,
  details?: {
    videoSize?: number
    fromUrl?: string
    toUrl?: string
    error?: string
  }
) {
  const message = success
    ? 'Video migration completed successfully'
    : 'Video migration failed'

  const level = success ? LogLevel.INFO : LogLevel.ERROR

  logger[success ? 'info' : 'error'](message, {
    job_id: jobId,
    user_id: userId,
    duration_ms: duration,
    metadata: details,
  })
}

/**
 * Log storage usage
 */
export function logStorageUsage(
  logger: StructuredLogger,
  usedBytes: number,
  totalBytes: number
) {
  const usedGB = usedBytes / (1024 * 1024 * 1024)
  const totalGB = totalBytes / (1024 * 1024 * 1024)
  const percentage = Math.round((usedBytes / totalBytes) * 100)

  const level = percentage >= 90 ? LogLevel.CRITICAL
    : percentage >= 80 ? LogLevel.WARN
    : LogLevel.INFO

  const message = `Storage usage: ${percentage}% (${usedGB.toFixed(2)}GB / ${totalGB.toFixed(2)}GB)`

  if (level === LogLevel.CRITICAL) {
    logger.critical(message, undefined, {
      metadata: { usedGB, totalGB, percentage },
    })
  } else if (level === LogLevel.WARN) {
    logger.warn(message, {
      metadata: { usedGB, totalGB, percentage },
    })
  } else {
    logger.info(message, {
      metadata: { usedGB, totalGB, percentage },
    })
  }
}

/**
 * Log credit transactions
 */
export function logCreditTransaction(
  logger: StructuredLogger,
  userId: string,
  operation: 'deduct' | 'add' | 'refund',
  amount: number,
  success: boolean,
  balanceAfter?: number,
  error?: string
) {
  const message = success
    ? `Credit ${operation} successful: ${amount} credits`
    : `Credit ${operation} failed: ${amount} credits`

  if (success) {
    logger.info(message, {
      user_id: userId,
      metadata: {
        operation,
        amount,
        balance_after: balanceAfter,
      },
    })
  } else {
    logger.error(message, undefined, {
      user_id: userId,
      metadata: {
        operation,
        amount,
        error,
      },
    })
  }
}

/**
 * Log rate limit events
 */
export function logRateLimit(
  logger: StructuredLogger,
  userId: string,
  action: string,
  allowed: boolean,
  currentCount: number,
  limit: number
) {
  const message = allowed
    ? `Rate limit check passed: ${action}`
    : `Rate limit exceeded: ${action}`

  if (allowed) {
    logger.debug(message, {
      user_id: userId,
      metadata: {
        action,
        current_count: currentCount,
        limit,
      },
    })
  } else {
    logger.warn(message, {
      user_id: userId,
      metadata: {
        action,
        current_count: currentCount,
        limit,
        exceeded_by: currentCount - limit,
      },
    })
  }
}

/**
 * Log API requests
 */
export function logAPIRequest(
  logger: StructuredLogger,
  method: string,
  path: string,
  statusCode: number,
  duration: number,
  userId?: string,
  error?: string
) {
  const success = statusCode >= 200 && statusCode < 400
  const message = `${method} ${path} - ${statusCode}`

  const context: LogContext = {
    user_id: userId,
    duration_ms: duration,
    metadata: {
      method,
      path,
      status_code: statusCode,
      error,
    },
  }

  if (success) {
    logger.info(message, context)
  } else if (statusCode >= 500) {
    logger.error(message, undefined, context)
  } else {
    logger.warn(message, context)
  }
}

/**
 * Create a logger instance for a function
 */
export function createLogger(functionName: string): StructuredLogger {
  return new StructuredLogger(functionName)
}

// Legacy compatibility - keep the old logEvent function
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

// Export types
export type { LogContext, LogEntry, StructuredLogger }

