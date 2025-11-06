-- Migration: Add pricing fields to models table
-- Version: 1.1
-- Date: 2025-11-06
-- Purpose: Add pricing_type, has_audio, and base_price columns for dynamic pricing support

-- =====================================================
-- Add new pricing columns to models table
-- =====================================================

ALTER TABLE models 
ADD COLUMN IF NOT EXISTS pricing_type TEXT 
  CHECK (pricing_type IN ('per_second', 'per_video')),
ADD COLUMN IF NOT EXISTS has_audio BOOLEAN,
ADD COLUMN IF NOT EXISTS base_price NUMERIC(10,2);

-- =====================================================
-- Add index for pricing_type (optional, for filtering)
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_models_pricing_type ON models(pricing_type);

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Pricing fields added to models table successfully!';
    RAISE NOTICE '   - pricing_type: per_second | per_video (no default - provide when inserting)';
    RAISE NOTICE '   - has_audio: boolean (no default - provide when inserting)';
    RAISE NOTICE '   - base_price: numeric(10,2) (no default - provide when inserting)';
    RAISE NOTICE '   - Index created: idx_models_pricing_type';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Note: You must provide these values when inserting new models.';
    RAISE NOTICE '   Existing rows will have NULL values - update them manually if needed.';
END $$;

