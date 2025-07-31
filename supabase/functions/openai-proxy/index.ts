import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'
import { safeLogError } from '../shared/utils.ts'
import { LogEntry } from '../shared/types.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface OpenAIRequest {
  model: string
  messages: { role: string; content: string }[]
  temperature?: number
  max_tokens?: number
}

serve(async (req) => {
  console.log('🔍 OpenAI Proxy: Function called')
  console.log('🔍 Request method:', req.method)
  console.log('🔍 Request URL:', req.url)
  
  // Handle CORS
  if (req.method === 'OPTIONS') {
    console.log('🔍 Handling CORS preflight')
    return new Response('ok', { headers: corsHeaders })
  }

  // Initialize Supabase client first for logging
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  
  console.log('🔍 Environment check:')
  console.log('  - SUPABASE_URL:', supabaseUrl ? 'SET' : 'MISSING')
  console.log('  - SUPABASE_SERVICE_ROLE_KEY:', supabaseServiceKey ? 'SET' : 'MISSING')
  
  if (!supabaseUrl || !supabaseServiceKey) {
    console.error('❌ Missing Supabase environment variables')
    return new Response(JSON.stringify({ error: 'Service configuration error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
  
  const supabase = createClient(supabaseUrl, supabaseServiceKey)
  
  try {
    // Log function start
    await safeLogError(supabase, {
      event_type: 'openai_proxy_call',
      status: 'info',
      message: 'OpenAI proxy function called',
      metadata: {
        method: req.method,
        url: req.url,
        timestamp: new Date().toISOString()
      }
    })
    
    // Get auth header
    const authHeader = req.headers.get('Authorization')
    console.log('🔍 Auth header:', authHeader ? 'PRESENT' : 'MISSING')
    
    if (!authHeader) {
      console.error('❌ No authorization header provided')
      await safeLogError(supabase, {
        event_type: 'openai_proxy_auth_failed',
        status: 'error',
        message: 'No authorization header provided',
        metadata: { error_type: 'missing_auth_header' }
      })
      return new Response(JSON.stringify({ error: 'No authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Verify the user's JWT
    const token = authHeader.replace('Bearer ', '')
    console.log('🔍 Extracted token length:', token.length)
    
    const { data: { user }, error: userError } = await supabase.auth.getUser(token)
    
    if (userError || !user) {
      console.error('❌ User authentication failed:', userError)
      await safeLogError(supabase, {
        event_type: 'openai_proxy_auth_failed',
        status: 'error',
        message: `User authentication failed: ${userError?.message || 'No user found'}`,
        metadata: {
          error_type: 'invalid_token',
          supabase_error: userError
        }
      })
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    
    console.log('✅ User authenticated:', user.id)
    await safeLogError(supabase, {
      event_type: 'openai_proxy_auth_success',
      status: 'success',
      message: 'User authenticated successfully',
      user_id: user.id,
      metadata: { user_id: user.id }
    })

    // Parse request
    let requestBody: OpenAIRequest
    try {
      requestBody = await req.json()
      console.log('🔍 Request body parsed successfully')
    } catch (parseError) {
      console.error('❌ Failed to parse request body:', parseError)
      await safeLogError(supabase, {
        event_type: 'openai_proxy_request_parse_failed',
        status: 'error',
        message: `Failed to parse request body: ${parseError.message}`,
        user_id: user.id,
        metadata: { error: parseError.toString() }
      })
      return new Response(JSON.stringify({ error: 'Invalid request body' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    
    const { model = "gpt-4o-mini", messages, temperature = 0.7, max_tokens = 1000 } = requestBody
    
    console.log('🔍 Request parameters:')
    console.log('  - Model:', model)
    console.log('  - Messages count:', messages?.length || 0)
    console.log('  - Temperature:', temperature)
    console.log('  - Max tokens:', max_tokens)

    // Validate messages
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      console.error('❌ Invalid messages array')
      await safeLogError(supabase, {
        event_type: 'openai_proxy_validation_failed',
        status: 'error',
        message: 'Messages array is required and must not be empty',
        user_id: user.id,
        metadata: {
          validation_error: 'invalid_messages',
          messages_type: typeof messages,
          messages_length: messages?.length || 0
        }
      })
      return new Response(JSON.stringify({ error: 'Messages array is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Get OpenAI key
    const openAIKey = Deno.env.get('OPENAI_API_KEY')
    console.log('🔍 OpenAI API key:', openAIKey ? 'SET' : 'MISSING')
    
    if (!openAIKey) {
      console.error('❌ OpenAI API key not configured')
      await safeLogError(supabase, {
        event_type: 'openai_proxy_config_error',
        status: 'error',
        message: 'OpenAI API key not configured in environment',
        user_id: user.id,
        metadata: {
          error_type: 'missing_openai_key',
          available_env_vars: Object.keys(Deno.env.toObject()).filter(key => key.includes('API')),
          all_env_vars: Object.keys(Deno.env.toObject())
        }
      })
      return new Response(JSON.stringify({ error: 'Service not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    
    console.log('✅ OpenAI API key available, making request to OpenAI')
    await safeLogError(supabase, {
      event_type: 'openai_api_call_start',
      status: 'info',
      message: 'Starting OpenAI API call',
      user_id: user.id,
      metadata: {
        model,
        messages_count: messages.length,
        temperature,
        max_tokens
      }
    })

    // Make request to OpenAI
    console.log('🔍 Making request to OpenAI API')
    const openAIRequestBody = {
      model,
      messages,
      temperature,
      max_tokens,
      user: user.id // Track usage per user
    }
    
    const openAIResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openAIKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(openAIRequestBody),
    })
    
    console.log('🔍 OpenAI response status:', openAIResponse.status)
    console.log('🔍 OpenAI response ok:', openAIResponse.ok)

    if (!openAIResponse.ok) {
      const error = await openAIResponse.text()
      console.error('❌ OpenAI API error:', error)
      
      await safeLogError(supabase, {
        event_type: 'openai_api_call_failed',
        status: 'error',
        message: `OpenAI API call failed with status ${openAIResponse.status}`,
        user_id: user.id,
        metadata: {
          status_code: openAIResponse.status,
          error_response: error,
          request_model: model,
          messages_count: messages.length
        }
      })
      
      return new Response(JSON.stringify({ error: 'AI service error' }), {
        status: openAIResponse.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const data = await openAIResponse.json()
    console.log('✅ OpenAI API call successful')
    console.log('🔍 Response data keys:', Object.keys(data))
    console.log('🔍 Choices count:', data.choices?.length || 0)
    
    await safeLogError(supabase, {
      event_type: 'openai_api_call_success',
      status: 'success',
      message: 'OpenAI API call completed successfully',
      user_id: user.id,
      metadata: {
        model,
        messages_count: messages.length,
        response_choices: data.choices?.length || 0,
        usage: data.usage
      }
    })

    // Return OpenAI response
    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('❌ Proxy error:', error)
    console.error('❌ Error stack:', error.stack)
    
    // Try to log error to database
    try {
      await safeLogError(supabase, {
        event_type: 'openai_proxy_error',
        status: 'error',
        message: `OpenAI proxy internal error: ${error.message}`,
        metadata: {
          error: error.toString(),
          stack: error.stack,
          error_type: error.name
        }
      })
    } catch (logError) {
      console.error('❌ Failed to log error:', logError)
    }
    
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})