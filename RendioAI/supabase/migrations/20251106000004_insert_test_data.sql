-- Migration: Insert test data for themes architecture
-- Version: 1.0
-- Date: 2025-11-06
-- Purpose: Insert Sora 2 model (active) and test themes

-- =====================================================
-- Insert/Update Sora 2 Model (Active Model)
-- =====================================================

-- First, ensure no other models are active (set all to false)
UPDATE models SET is_active = false WHERE is_active = true;

-- Insert or update Sora 2 model with all new fields
DO $$
DECLARE
    existing_model_id UUID;
BEGIN
    -- Check if Sora 2 model already exists
    SELECT id INTO existing_model_id
    FROM models
    WHERE provider = 'fal' 
      AND provider_model_id = 'fal-ai/sora-2/image-to-video'
    LIMIT 1;
    
    IF existing_model_id IS NOT NULL THEN
        -- Update existing model
        UPDATE models SET
            name = 'Sora 2 Image-to-Video',
            category = 'image-to-video',
            description = 'OpenAI Sora 2 model for generating videos from images and prompts',
            pricing_type = 'per_second',
            base_price = 0.1,
            has_audio = true,
            is_active = true,
            required_fields = '{
                "requires_prompt": true,
                "requires_image": true,
                "requires_settings": true,
                "settings": {
                    "resolution": {
                        "required": false,
                        "default": "auto",
                        "options": ["auto", "720p"]
                    },
                    "aspect_ratio": {
                        "required": false,
                        "default": "auto",
                        "options": ["auto", "9:16", "16:9"]
                    },
                    "duration": {
                        "required": false,
                        "default": 4,
                        "options": [4, 8, 12]
                    }
                }
            }'::jsonb,
            is_available = true
        WHERE id = existing_model_id;
        
        RAISE NOTICE '✅ Updated existing Sora 2 model (ID: %)', existing_model_id;
    ELSE
        -- Insert new model
        INSERT INTO models (
            name, 
            category, 
            description,
            provider, 
            provider_model_id,
            pricing_type, 
            base_price, 
            has_audio, 
            is_active,
            required_fields, 
            is_available,
            cost_per_generation  -- Keep for backward compatibility
        ) VALUES (
            'Sora 2 Image-to-Video',
            'image-to-video',
            'OpenAI Sora 2 model for generating videos from images and prompts',
            'fal',
            'fal-ai/sora-2/image-to-video',
            'per_second',
            0.1,
            true,
            true,  -- ← Only ONE model should have is_active = true
            '{
                "requires_prompt": true,
                "requires_image": true,
                "requires_settings": true,
                "settings": {
                    "resolution": {
                        "required": false,
                        "default": "auto",
                        "options": ["auto", "720p"]
                    },
                    "aspect_ratio": {
                        "required": false,
                        "default": "auto",
                        "options": ["auto", "9:16", "16:9"]
                    },
                    "duration": {
                        "required": false,
                        "default": 4,
                        "options": [4, 8, 12]
                    }
                }
            }'::jsonb,
            true,
            4  -- cost_per_generation: $0.1 * 4 seconds = $0.4 = 4 credits (for 4-second default, backward compatibility only)
        );
        
        RAISE NOTICE '✅ Inserted new Sora 2 model';
    END IF;
END $$;

-- =====================================================
-- Insert Test Themes
-- =====================================================

INSERT INTO themes (name, description, prompt, is_featured, default_settings) VALUES
(
    'Christmas Magic',
    'Create festive holiday videos with snow, decorations, and warm atmosphere',
    'A cozy Christmas scene with snow falling gently, warm fireplace glowing, beautifully decorated tree with twinkling lights, family gathered around, holiday music playing softly in the background',
    true,
    '{"duration": 8, "aspect_ratio": "16:9"}'::jsonb
),
(
    'Thanksgiving Feast',
    'Capture the warmth of Thanksgiving with family, food, and autumn vibes',
    'A warm Thanksgiving dinner table with golden turkey, autumn decorations, family members laughing and sharing stories, soft candlelight, cozy autumn atmosphere',
    true,
    '{"duration": 8, "aspect_ratio": "16:9"}'::jsonb
),
(
    'Halloween Spooky',
    'Create eerie and spooky Halloween videos',
    'A spooky Halloween night with fog rolling through a graveyard, jack-o-lanterns glowing, eerie shadows, full moon, mysterious atmosphere',
    true,
    '{"duration": 8, "aspect_ratio": "16:9"}'::jsonb
),
(
    'Summer Beach',
    'Capture sunny beach vibes with waves, sand, and relaxation',
    'A beautiful sunny beach with crystal clear turquoise water, gentle waves lapping the shore, golden sand, palm trees swaying in the breeze, people enjoying the warm weather',
    true,
    '{"duration": 8, "aspect_ratio": "16:9"}'::jsonb
),
(
    'City Nightlife',
    'Experience vibrant urban energy with neon lights and city streets',
    'A vibrant city street at night with neon lights reflecting on wet pavement, people walking, cars passing by, urban energy and excitement in the air',
    true,
    '{"duration": 8, "aspect_ratio": "16:9"}'::jsonb
)
ON CONFLICT DO NOTHING;  -- Prevent duplicates if run multiple times

-- =====================================================
-- Success message
-- =====================================================

DO $$
DECLARE
    active_model_count INTEGER;
    theme_count INTEGER;
BEGIN
    -- Count active models
    SELECT COUNT(*) INTO active_model_count
    FROM models
    WHERE is_active = true;
    
    -- Count themes
    SELECT COUNT(*) INTO theme_count
    FROM themes;
    
    RAISE NOTICE '✅ Test data inserted successfully!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Summary:';
    RAISE NOTICE '   - Active models: %', active_model_count;
    RAISE NOTICE '   - Themes created: %', theme_count;
    RAISE NOTICE '';
    RAISE NOTICE '🎬 Active Model:';
    RAISE NOTICE '   - Sora 2 Image-to-Video';
    RAISE NOTICE '   - Pricing: $0.1 per second';
    RAISE NOTICE '   - Has audio: true';
    RAISE NOTICE '';
    RAISE NOTICE '🎨 Themes:';
    RAISE NOTICE '   - Christmas Magic';
    RAISE NOTICE '   - Thanksgiving Feast';
    RAISE NOTICE '   - Halloween Spooky';
    RAISE NOTICE '   - Summer Beach';
    RAISE NOTICE '   - City Nightlife';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Note: Verify data in Supabase dashboard before proceeding.';
END $$;

