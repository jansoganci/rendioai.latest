-- Migration: Create themes table
-- Version: 1.0
-- Date: 2025-11-06
-- Purpose: Create themes table for user-facing content/vibes (decoupled from AI models)

-- =====================================================
-- Table: themes
-- Purpose: Store user-facing themes/vibes with default prompts
-- =====================================================

CREATE TABLE IF NOT EXISTS themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    thumbnail_url TEXT,
    prompt TEXT NOT NULL,
    is_featured BOOLEAN DEFAULT false,
    is_available BOOLEAN DEFAULT true,
    default_settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- Indexes for themes table
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_themes_featured ON themes(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_themes_available ON themes(is_available) WHERE is_available = true;

-- =====================================================
-- Enable Row Level Security (RLS)
-- =====================================================

ALTER TABLE themes ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS Policies for themes table
-- =====================================================

-- Policy: Anyone can view available themes
CREATE POLICY "Anyone can view available themes"
ON themes FOR SELECT
USING (is_available = true);

-- Note: Only backend (service_role) can modify themes
-- No INSERT/UPDATE/DELETE policies needed for users

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Themes table created successfully!';
    RAISE NOTICE '   - id: UUID (primary key)';
    RAISE NOTICE '   - name: TEXT NOT NULL';
    RAISE NOTICE '   - description: TEXT';
    RAISE NOTICE '   - thumbnail_url: TEXT';
    RAISE NOTICE '   - prompt: TEXT NOT NULL (default prompt for theme)';
    RAISE NOTICE '   - is_featured: BOOLEAN (default: false)';
    RAISE NOTICE '   - is_available: BOOLEAN (default: true)';
    RAISE NOTICE '   - default_settings: JSONB (default: {})';
    RAISE NOTICE '   - created_at: TIMESTAMPTZ';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Indexes created:';
    RAISE NOTICE '   - idx_themes_featured (partial index on is_featured = true)';
    RAISE NOTICE '   - idx_themes_available (partial index on is_available = true)';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 RLS enabled with policy: "Anyone can view available themes"';
    RAISE NOTICE '   - Users can SELECT themes where is_available = true';
    RAISE NOTICE '   - Only backend (service_role) can INSERT/UPDATE/DELETE';
END $$;

