/**
 * Telegram Alert Module
 * Sends critical alerts to Telegram for immediate notification
 */

interface TelegramMessage {
  chat_id: string
  text: string
  parse_mode?: 'Markdown' | 'HTML'
  disable_notification?: boolean
}

interface AlertContext {
  function?: string
  user_id?: string
  job_id?: string
  error?: string
  metadata?: Record<string, any>
}

// Alert severity levels
export enum AlertLevel {
  INFO = 'ℹ️',
  WARNING = '⚠️',
  ERROR = '❌',
  CRITICAL = '🚨',
  SUCCESS = '✅',
}

class TelegramNotifier {
  private botToken: string | undefined
  private chatId: string | undefined
  private enabled: boolean

  constructor() {
    this.botToken = Deno.env.get('TELEGRAM_BOT_TOKEN')
    this.chatId = Deno.env.get('TELEGRAM_CHAT_ID')
    this.enabled = !!(this.botToken && this.chatId)

    if (!this.enabled) {
      console.warn('[Telegram] Bot token or chat ID not configured, alerts disabled')
    }
  }

  /**
   * Send a message to Telegram
   */
  private async sendMessage(message: TelegramMessage): Promise<boolean> {
    if (!this.enabled) {
      console.log('[Telegram] Alert (not sent):', message.text)
      return false
    }

    try {
      const response = await fetch(
        `https://api.telegram.org/bot${this.botToken}/sendMessage`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(message),
        }
      )

      if (!response.ok) {
        const error = await response.text()
        console.error('[Telegram] Failed to send alert:', error)
        return false
      }

      return true
    } catch (error) {
      console.error('[Telegram] Error sending alert:', error)
      return false
    }
  }

  /**
   * Format alert message with context
   */
  private formatMessage(
    level: AlertLevel,
    title: string,
    description: string,
    context?: AlertContext
  ): string {
    const environment = Deno.env.get('ENVIRONMENT') || 'development'
    const timestamp = new Date().toISOString()

    let message = `${level} *${title}*\n\n`
    message += `${description}\n\n`
    message += `📍 Environment: \`${environment}\`\n`
    message += `🕐 Time: \`${timestamp}\`\n`

    if (context?.function) {
      message += `⚡ Function: \`${context.function}\`\n`
    }

    if (context?.user_id) {
      message += `👤 User: \`${context.user_id}\`\n`
    }

    if (context?.job_id) {
      message += `🎯 Job: \`${context.job_id}\`\n`
    }

    if (context?.error) {
      message += `\n*Error Details:*\n\`\`\`\n${context.error}\n\`\`\`\n`
    }

    if (context?.metadata) {
      message += `\n*Additional Info:*\n`
      for (const [key, value] of Object.entries(context.metadata)) {
        message += `• ${key}: \`${JSON.stringify(value)}\`\n`
      }
    }

    return message
  }

  /**
   * Send an alert
   */
  async alert(
    level: AlertLevel,
    title: string,
    description: string,
    context?: AlertContext
  ): Promise<boolean> {
    const message = this.formatMessage(level, title, description, context)

    return await this.sendMessage({
      chat_id: this.chatId!,
      text: message,
      parse_mode: 'Markdown',
      disable_notification: level === AlertLevel.INFO,
    })
  }
}

// Singleton instance
const notifier = new TelegramNotifier()

/**
 * Send critical alert for video migration failures
 */
export async function alertVideoMigrationFailure(
  jobId: string,
  userId: string,
  error: Error,
  videoUrl?: string
) {
  await notifier.alert(
    AlertLevel.ERROR,
    'Video Migration Failed',
    'Failed to migrate video from FalAI to Supabase Storage',
    {
      function: 'get-video-status',
      user_id: userId,
      job_id: jobId,
      error: error.message,
      metadata: {
        video_url: videoUrl,
        error_stack: error.stack,
      },
    }
  )
}

/**
 * Send alert for storage usage
 */
export async function alertStorageUsage(
  usedGB: number,
  totalGB: number,
  percentage: number
) {
  const level = percentage >= 90 ? AlertLevel.CRITICAL : AlertLevel.WARNING
  const title = percentage >= 90 ? 'Critical Storage Usage' : 'High Storage Usage'

  await notifier.alert(
    level,
    title,
    `Storage is ${percentage}% full`,
    {
      metadata: {
        used_gb: usedGB.toFixed(2),
        total_gb: totalGB.toFixed(2),
        percentage: `${percentage}%`,
      },
    }
  )
}

/**
 * Send alert for provider errors
 */
export async function alertProviderError(
  provider: string,
  error: Error,
  context?: {
    user_id?: string
    job_id?: string
    request?: any
  }
) {
  await notifier.alert(
    AlertLevel.ERROR,
    `${provider} Provider Error`,
    `Error occurred while communicating with ${provider}`,
    {
      function: context?.job_id ? 'generate-video' : 'unknown',
      user_id: context?.user_id,
      job_id: context?.job_id,
      error: error.message,
      metadata: {
        provider,
        request: context?.request,
      },
    }
  )
}

/**
 * Send alert for rate limit violations
 */
export async function alertRateLimitViolation(
  userId: string,
  action: string,
  attempts: number,
  limit: number
) {
  await notifier.alert(
    AlertLevel.WARNING,
    'Rate Limit Exceeded',
    `User exceeded rate limit for ${action}`,
    {
      user_id: userId,
      metadata: {
        action,
        attempts,
        limit,
        exceeded_by: attempts - limit,
      },
    }
  )
}

/**
 * Send alert for credit system errors
 */
export async function alertCreditSystemError(
  userId: string,
  operation: string,
  error: Error,
  amount?: number
) {
  await notifier.alert(
    AlertLevel.CRITICAL,
    'Credit System Error',
    `Failed to ${operation} credits for user`,
    {
      function: 'credit-system',
      user_id: userId,
      error: error.message,
      metadata: {
        operation,
        amount,
      },
    }
  )
}

/**
 * Send alert for authentication failures
 */
export async function alertAuthFailure(
  reason: string,
  deviceId?: string,
  error?: Error
) {
  await notifier.alert(
    AlertLevel.ERROR,
    'Authentication Failure',
    reason,
    {
      function: 'device-check',
      error: error?.message,
      metadata: {
        device_id: deviceId,
      },
    }
  )
}

/**
 * Send success notification for important operations
 */
export async function alertSuccess(
  title: string,
  description: string,
  context?: AlertContext
) {
  await notifier.alert(AlertLevel.SUCCESS, title, description, context)
}

/**
 * Send info notification
 */
export async function alertInfo(
  title: string,
  description: string,
  context?: AlertContext
) {
  await notifier.alert(AlertLevel.INFO, title, description, context)
}

/**
 * Send custom alert
 */
export async function sendAlert(
  level: AlertLevel,
  title: string,
  description: string,
  context?: AlertContext
) {
  return await notifier.alert(level, title, description, context)
}

// Export the alert levels for external use
export { notifier }