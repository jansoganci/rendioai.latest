/**
 * Apple Server-to-Server Notifications Handler
 * Receives notifications from Apple about IAP events (refunds, renewals, etc.)
 *
 * Documentation: https://developer.apple.com/documentation/appstoreservernotifications
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// Apple notification types we care about
const NOTIFICATION_TYPES = {
  REFUND: 'REFUND',
  CONSUMPTION_REQUEST: 'CONSUMPTION_REQUEST',
  DID_RENEW: 'DID_RENEW',
  DID_FAIL_TO_RENEW: 'DID_FAIL_TO_RENEW',
}

serve(async (req) => {
  // Only accept POST requests
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const notification = await req.json()
    console.log('📥 Received Apple notification:', JSON.stringify(notification, null, 2))

    // Extract notification type and transaction info
    const notificationType = notification.notificationType
    const transactionInfo = notification.data?.signedTransactionInfo

    if (!transactionInfo) {
      console.log('⚠️ No transaction info in notification')
      return new Response('No transaction info', { status: 400 })
    }

    // Decode the JWT transaction info (Apple sends it as JWT)
    // For now, we'll extract the transaction ID from the payload
    // In production, you should verify the JWT signature
    const transactionId = notification.data?.transactionId ||
                         notification.data?.originalTransactionId

    if (!transactionId) {
      console.log('⚠️ No transaction ID found')
      return new Response('No transaction ID', { status: 400 })
    }

    console.log(`📋 Notification Type: ${notificationType}`)
    console.log(`🆔 Transaction ID: ${transactionId}`)

    // Handle different notification types
    switch (notificationType) {
      case NOTIFICATION_TYPES.REFUND:
        await handleRefund(transactionId)
        break

      case NOTIFICATION_TYPES.CONSUMPTION_REQUEST:
        await handleConsumptionRequest(transactionId)
        break

      default:
        console.log(`ℹ️ Unhandled notification type: ${notificationType}`)
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Notification processed' }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('❌ Error processing notification:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

/**
 * Handle REFUND notification
 * Deduct credits from user when Apple refunds a purchase
 */
async function handleRefund(transactionId: string) {
  console.log(`🔄 Processing refund for transaction: ${transactionId}`)

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  // 1. Find the original purchase in quota_log
  const { data: purchase, error: fetchError } = await supabase
    .from('quota_log')
    .select('*')
    .eq('transaction_id', transactionId)
    .eq('status', 'completed')
    .single()

  if (fetchError || !purchase) {
    console.log(`⚠️ Purchase not found or already refunded: ${transactionId}`)
    return
  }

  console.log(`✅ Found purchase:`, purchase)

  const userId = purchase.user_id
  const creditsToDeduct = purchase.change // This was a positive number when added

  // 2. Deduct credits from user
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('credits_remaining')
    .eq('id', userId)
    .single()

  if (userError || !user) {
    console.error(`❌ User not found: ${userId}`)
    throw new Error('User not found')
  }

  const newBalance = user.credits_remaining - creditsToDeduct

  // Update user credits
  const { error: updateError } = await supabase
    .from('users')
    .update({ credits_remaining: newBalance })
    .eq('id', userId)

  if (updateError) {
    console.error(`❌ Failed to update user credits:`, updateError)
    throw new Error('Failed to update credits')
  }

  console.log(`💳 Deducted ${creditsToDeduct} credits from user ${userId}`)
  console.log(`📊 New balance: ${newBalance}`)

  // 3. Mark the purchase as refunded
  const { error: statusError } = await supabase
    .from('quota_log')
    .update({ status: 'refunded' })
    .eq('transaction_id', transactionId)

  if (statusError) {
    console.error(`❌ Failed to mark as refunded:`, statusError)
    throw new Error('Failed to update status')
  }

  // 4. Create a refund log entry
  const { error: logError } = await supabase
    .from('quota_log')
    .insert({
      user_id: userId,
      change: -creditsToDeduct,
      reason: 'apple_refund',
      transaction_id: `${transactionId}_refund`,
      balance_after: newBalance,
    })

  if (logError) {
    console.error(`❌ Failed to create refund log:`, logError)
  }

  console.log(`✅ Refund processed successfully for ${transactionId}`)
}

/**
 * Handle CONSUMPTION_REQUEST notification
 * Apple asks if the user has consumed the credits
 * We respond with consumption status (always consumed for credits)
 */
async function handleConsumptionRequest(transactionId: string) {
  console.log(`📊 Consumption request for transaction: ${transactionId}`)

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  // Check if credits were used
  const { data: purchase } = await supabase
    .from('quota_log')
    .select('*')
    .eq('transaction_id', transactionId)
    .single()

  if (purchase) {
    // Credits are consumable and always considered "consumed"
    console.log(`✅ Credits consumed for transaction: ${transactionId}`)
    // Apple expects us to respond via their API, but for now just log
  }
}
