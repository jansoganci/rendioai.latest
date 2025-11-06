-- Migration: Update models table with new columns for themes architecture
-- Version: 1.0
-- Date: 2025-11-06
-- Purpose: Add is_active, required_fields columns and index for dynamic model selection

-- =====================================================
-- Add new columns to models table
-- =====================================================

ALTER TABLE models 
ADD COLUMN IF NOT EXISTS pricing_type TEXT 
  CHECK (pricing_type IN ('per_second', 'per_video')),
ADD COLUMN IF NOT EXISTS base_price NUMERIC(10,2),
ADD COLUMN IF NOT EXISTS has_audio BOOLEAN,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS required_fields JSONB DEFAULT '{}';

-- =====================================================
-- Add index on is_active for performance
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_models_active ON models(is_active) WHERE is_active = true;

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Models table updated successfully!';
    RAISE NOTICE '   - pricing_type: per_second | per_video (no default)';
    RAISE NOTICE '   - base_price: numeric(10,2) (no default)';
    RAISE NOTICE '   - has_audio: boolean (no default)';
    RAISE NOTICE '   - is_active: boolean (default: false)';
    RAISE NOTICE '   - required_fields: jsonb (default: {})';
    RAISE NOTICE '   - Index created: idx_models_active (partial index on is_active = true)';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Note: Only ONE model should have is_active = true at a time.';
    RAISE NOTICE '   You must provide pricing_type, base_price, and has_audio when inserting new models.';
END $$;

