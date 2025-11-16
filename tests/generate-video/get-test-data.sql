-- Get Test Data for Generate Video Endpoint Testing
-- Run this in Supabase SQL Editor to get required test data

-- 1. Get a user_id with credits
SELECT 
    id as user_id, 
    credits_remaining,
    'Copy this USER_ID' as instruction
FROM users 
WHERE credits_remaining > 0 
LIMIT 1;

-- 2. Get a theme_id
SELECT 
    id as theme_id, 
    name as theme_name,
    is_available,
    'Copy this THEME_ID' as instruction
FROM themes 
WHERE is_available = true 
LIMIT 1;

-- 3. Verify active model exists
SELECT 
    id as model_id,
    name, 
    provider_model_id, 
    pricing_type, 
    base_price, 
    is_active, 
    is_available,
    'Verify this model is active' as instruction
FROM models 
WHERE is_active = true AND is_available = true;

