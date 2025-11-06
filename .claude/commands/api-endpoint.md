# Create Supabase Edge Function

You are creating a Supabase Edge Function for Rendio AI's backend API layer.

## Instructions

Ask the user:
1. **Endpoint name** (e.g., "generate-video", "get-user-credits")
2. **HTTP method** (GET, POST, PUT, DELETE)
3. **Purpose** (what it does)
4. **Input parameters** (request body/query)
5. **Output** (response format)

Then create a complete Edge Function implementation.

### File Structure
```
supabase/functions/{endpoint-name}/
├── index.ts
└── README.md
```

### Template Structure

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 2. Parse request
    const { param1, param2 } = await req.json()

    // 3. Validate input
    if (!param1) {
      throw new Error('Missing required parameter: param1')
    }

    // 4. Business logic
    // - Check permissions (RLS)
    // - Validate data
    // - Process request
    // - Update database

    // 5. Return response
    return new Response(
      JSON.stringify({
        success: true,
        data: result
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
```

### Required Checks

1. **Authentication**
   - Verify user/device ID
   - Check RLS policies
   - Validate DeviceCheck token (for guests)

2. **Input Validation**
   - Required parameters present
   - Type checking
   - Range/format validation

3. **Error Handling**
   - Try/catch blocks
   - Proper HTTP status codes
   - Meaningful error messages

4. **Security**
   - No API keys in response
   - Proper CORS headers
   - Service role key only in backend
   - SQL injection prevention

5. **Logging**
   - Success/error events
   - Telegram notifications (for critical errors)
   - No sensitive data in logs

### Provider Adapter (if AI-related)

For video generation endpoints, use the adapter pattern:

```typescript
interface VideoModelAdapter {
  generate(input: {
    prompt: string
    settings: Record<string, any>
    modelInfo: any
  }): Promise<{ job_id: string; provider_status: string }>
}

// Import appropriate adapter
import { FalAdapter } from '../adapters/fal-adapter.ts'
import { SoraAdapter } from '../adapters/sora-adapter.ts'
```

### Database Operations

Use RLS-aware queries:
```typescript
const { data, error } = await supabaseClient
  .from('video_jobs')
  .select('*')
  .eq('user_id', userId)
  .single()
```

### Response Format

Standard success:
```json
{
  "success": true,
  "data": { ... }
}
```

Standard error:
```json
{
  "error": "Descriptive error message"
}
```

## Output

Provide:
1. **Complete Edge Function code**
2. **README.md** with:
   - Purpose
   - Request/response examples
   - Environment variables needed
   - Testing instructions
3. **Deployment command**
4. **Client-side Swift code** to call this endpoint
5. **RLS policies** (if new tables involved)
