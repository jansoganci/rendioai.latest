-- Migration: Create all core tables for Rendio AI
-- Version: 1.0
-- Date: 2025-11-05

-- =====================================================
-- Table: users
-- Purpose: Store user identity, auth, preferences, and credits
-- =====================================================

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT,
    device_id TEXT,
    apple_sub TEXT,
    is_guest BOOLEAN DEFAULT true,
    tier TEXT DEFAULT 'free' CHECK (tier IN ('free', 'premium')),
    credits_remaining INTEGER DEFAULT 0,
    credits_total INTEGER DEFAULT 0,
    initial_grant_claimed BOOLEAN DEFAULT false,
    language TEXT DEFAULT 'en' CHECK (language IN ('en', 'tr', 'es')),
    theme_preference TEXT DEFAULT 'system' CHECK (theme_preference IN ('system', 'light', 'dark')),
    is_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for users
CREATE INDEX idx_users_device_id ON users(device_id);
CREATE INDEX idx_users_apple_sub ON users(apple_sub);

-- Unique constraints
CREATE UNIQUE INDEX idx_users_device_id_unique ON users(device_id) WHERE device_id IS NOT NULL;
CREATE UNIQUE INDEX idx_users_apple_sub_unique ON users(apple_sub) WHERE apple_sub IS NOT NULL;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Table: models
-- Purpose: Metadata for video generation models
-- =====================================================

CREATE TABLE IF NOT EXISTS models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    cost_per_generation INTEGER NOT NULL,
    provider TEXT NOT NULL CHECK (provider IN ('fal', 'runway', 'pika')),
    provider_model_id TEXT NOT NULL,
    is_featured BOOLEAN DEFAULT false,
    is_available BOOLEAN DEFAULT true,
    thumbnail_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for models
CREATE INDEX idx_models_provider ON models(provider);
CREATE INDEX idx_models_featured ON models(is_featured) WHERE is_featured = true;
CREATE INDEX idx_models_available ON models(is_available) WHERE is_available = true;

-- =====================================================
-- Table: video_jobs
-- Purpose: Store video generation jobs and their status
-- =====================================================

CREATE TABLE IF NOT EXISTS video_jobs (
    job_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    model_id UUID NOT NULL REFERENCES models(id) ON DELETE RESTRICT,
    prompt TEXT NOT NULL,
    settings JSONB DEFAULT '{}'::jsonb,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    video_url TEXT,
    thumbnail_url TEXT,
    credits_used INTEGER NOT NULL,
    error_message TEXT,
    provider_job_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ
);

-- Indexes for video_jobs
CREATE INDEX idx_video_jobs_user ON video_jobs(user_id, created_at DESC);
CREATE INDEX idx_video_jobs_status ON video_jobs(status);
CREATE INDEX idx_video_jobs_provider ON video_jobs(provider_job_id);

-- =====================================================
-- Table: quota_log
-- Purpose: Track all credit transactions (audit trail)
-- =====================================================

CREATE TABLE IF NOT EXISTS quota_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID REFERENCES video_jobs(job_id) ON DELETE SET NULL,
    change INTEGER NOT NULL,
    reason TEXT NOT NULL,
    transaction_id TEXT,
    balance_after INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for quota_log
CREATE INDEX idx_quota_log_user ON quota_log(user_id, created_at DESC);
CREATE INDEX idx_quota_log_transaction ON quota_log(transaction_id);

-- Unique constraint for transaction_id (prevent duplicate IAP purchases)
CREATE UNIQUE INDEX idx_quota_log_transaction_unique ON quota_log(transaction_id) WHERE transaction_id IS NOT NULL;

-- =====================================================
-- Table: idempotency_log
-- Purpose: Prevent duplicate operations (e.g., double-charging)
-- =====================================================

CREATE TABLE IF NOT EXISTS idempotency_log (
    idempotency_key UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    job_id UUID REFERENCES video_jobs(job_id) ON DELETE SET NULL,
    operation_type TEXT NOT NULL,
    response_data JSONB NOT NULL,
    status_code INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '24 hours')
);

-- Indexes for idempotency_log
CREATE INDEX idx_idempotency_user ON idempotency_log(user_id, created_at);
CREATE INDEX idx_idempotency_expires ON idempotency_log(expires_at);

-- =====================================================
-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ All tables created successfully!';
    RAISE NOTICE '   - users (13 fields)';
    RAISE NOTICE '   - models (11 fields)';
    RAISE NOTICE '   - video_jobs (12 fields)';
    RAISE NOTICE '   - quota_log (8 fields)';
    RAISE NOTICE '   - idempotency_log (8 fields)';
END $$;
