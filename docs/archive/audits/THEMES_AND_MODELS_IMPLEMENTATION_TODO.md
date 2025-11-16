# ✅ Themes & Models Implementation Todo List

**Date:** 2025-11-06  
**Status:** ✅ **COMPLETE** - All phases implemented and tested  
**Completion Date:** 2025-01-XX  
**Reference:** See `THEMES_AND_MODELS_ARCHITECTURE_PLAN.md` for detailed specifications

---

## 📋 Overview

This is a step-by-step todo list for implementing the themes and models architecture. Each task is actionable and can be completed independently.

**Estimated Time:** 2-3 days for full implementation

---

## 🗄️ Phase 1: Database Setup

### Task 1.1: Create Migration for Models Table Updates ✅

**File:** `RendioAI/supabase/migrations/20251106000002_update_models_table.sql`

**What to do:**
- [x] Create new migration file
- [x] Add `pricing_type` column (TEXT, CHECK constraint)
- [x] Add `base_price` column (NUMERIC(10,2))
- [x] Add `has_audio` column (BOOLEAN)
- [x] Add `is_active` column (BOOLEAN, DEFAULT false)
- [x] Add `required_fields` column (JSONB, DEFAULT '{}')
- [x] Add index on `is_active` for performance
- [x] Test migration runs without errors

**SQL Template:**
```sql
-- Migration: Update models table with new columns
ALTER TABLE models 
ADD COLUMN IF NOT EXISTS pricing_type TEXT CHECK (pricing_type IN ('per_second', 'per_video')),
ADD COLUMN IF NOT EXISTS base_price NUMERIC(10,2),
ADD COLUMN IF NOT EXISTS has_audio BOOLEAN,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS required_fields JSONB DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_models_active ON models(is_active) WHERE is_active = true;
```

**Acceptance Criteria:**
- ✅ Migration runs successfully
- ✅ All columns exist in models table
- ✅ Index created

---

### Task 1.2: Create Migration for Themes Table ✅

**File:** `RendioAI/supabase/migrations/20251106000003_create_themes_table.sql`

**What to do:**
- [x] Create new migration file
- [x] Create `themes` table with all columns
- [x] Add indexes (featured, available)
- [x] Enable RLS
- [x] Create RLS policy for SELECT (anyone can view available themes)
- [x] Test migration runs without errors

**SQL Template:**
```sql
-- Migration: Create themes table
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

CREATE INDEX idx_themes_featured ON themes(is_featured) WHERE is_featured = true;
CREATE INDEX idx_themes_available ON themes(is_available) WHERE is_available = true;

ALTER TABLE themes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view available themes"
ON themes FOR SELECT
USING (is_available = true);
```

**Acceptance Criteria:**
- ✅ Themes table created
- ✅ Indexes created
- ✅ RLS enabled and policy created
- ✅ Can query themes via Supabase REST API

---

### Task 1.3: Insert Test Data ✅

**What to do:**
- [x] Insert Sora 2 model with all new fields:
  - Set `is_active = true`
  - Set `pricing_type = 'per_second'`
  - Set `base_price = 0.1` (updated to $0.1 per second)
  - Set `has_audio = true`
  - Set `required_fields` JSONB (see plan doc for structure)
- [x] Insert 3-5 test themes:
  - Christmas Magic
  - Thanksgiving Feast
  - Halloween Spooky
  - Summer Beach
  - City Nightlife
- [x] Verify data in Supabase dashboard

**SQL Template:**
```sql
-- Insert Sora 2 model
INSERT INTO models (
  name, category, provider, provider_model_id,
  pricing_type, base_price, has_audio, is_active,
  required_fields, is_available
) VALUES (
  'Sora 2 Image-to-Video',
  'image-to-video',
  'fal',
  'fal-ai/sora-2/image-to-video',
  'per_second',
  0.15,
  true,
  true,
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
  true
);

-- Insert themes
INSERT INTO themes (name, description, prompt, is_featured, default_settings) VALUES
('Christmas Magic', 'Create festive holiday videos', 'A cozy Christmas scene...', true, '{"duration": 8, "aspect_ratio": "16:9"}'::jsonb),
('Thanksgiving Feast', 'Capture Thanksgiving warmth', 'A warm Thanksgiving dinner...', true, '{"duration": 8, "aspect_ratio": "16:9"}'::jsonb),
('Halloween Spooky', 'Create spooky Halloween videos', 'A spooky Halloween night...', true, '{"duration": 8, "aspect_ratio": "16:9"}'::jsonb);
```

**Acceptance Criteria:**
- ✅ One model with `is_active = true`
- ✅ 3+ themes inserted
- ✅ Can query themes via REST API

---

## ⚙️ Phase 2: Backend Updates

### Task 2.1: Update generate-video Request Interface ✅

**File:** `RendioAI/supabase/functions/generate-video/index.ts`

**What to do:**
- [x] Change `GenerateVideoRequest` interface:
  - Replace `model_id: string` with `theme_id: string`
  - Keep `prompt: string` (user's prompt, may be modified)
- [x] Update function signature to use `theme_id`

**Code Changes:**
```typescript
interface GenerateVideoRequest {
  user_id: string
  theme_id: string      // Changed from model_id
  prompt: string        // User's prompt (may be modified from theme)
  image_url?: string
  settings?: {
    resolution?: 'auto' | '720p'
    aspect_ratio?: 'auto' | '9:16' | '16:9'
    duration?: 4 | 8 | 12
  }
}
```

**Acceptance Criteria:**
- ✅ Interface updated
- ✅ TypeScript compiles without errors

---

### Task 2.2: Update generate-video to Get Active Model ✅

**File:** `RendioAI/supabase/functions/generate-video/index.ts`

**What to do:**
- [x] Replace model fetch logic:
  - Remove: `SELECT * FROM models WHERE id = model_id`
  - Add: `SELECT * FROM models WHERE is_active = true AND is_available = true`
- [x] Add error handling if no active model found
- [x] Update error messages

**Code Location:** Around line 108-126

**Acceptance Criteria:**
- ✅ Fetches active model instead of using model_id
- ✅ Returns 404 if no active model
- ✅ Error messages updated

---

### Task 2.3: Add Theme Fetching to generate-video ✅

**File:** `RendioAI/supabase/functions/generate-video/index.ts`

**What to do:**
- [x] Add query to fetch theme:
  - `SELECT * FROM themes WHERE id = theme_id AND is_available = true`
- [x] Add error handling if theme not found
- [x] Store theme data (for reference, but use user's prompt)

**Code Location:** After active model fetch

**Acceptance Criteria:**
- ✅ Fetches theme successfully
- ✅ Returns 404 if theme not found
- ✅ Theme data available for reference

---

### Task 2.4: Add Dynamic Validation Based on required_fields ✅

**File:** `RendioAI/supabase/functions/generate-video/index.ts`

**What to do:**
- [x] Extract `required_fields` from active model
- [x] Validate `requires_prompt` → check if prompt exists
- [x] Validate `requires_image` → check if image_url exists
- [x] Validate `requires_settings` → validate duration, aspect_ratio, resolution against allowed options
- [x] Return appropriate error messages

**Code Location:** After theme fetch, before credit deduction

**Acceptance Criteria:**
- ✅ Validates prompt if required
- ✅ Validates image_url if required
- ✅ Validates settings against allowed options
- ✅ Returns clear error messages

---

### Task 2.5: Add Dynamic Cost Calculation ✅

**File:** `RendioAI/supabase/functions/generate-video/index.ts`

**What to do:**
- [x] Check `pricing_type` from active model
- [x] If `pricing_type === 'per_second'`:
  - Get duration from settings or default
  - Calculate: `costInDollars = base_price * duration`
- [x] If `pricing_type === 'per_video'`:
  - Calculate: `costInDollars = base_price`
- [x] Convert to credits: `creditsToDeduct = Math.round(costInDollars * 10)` (conversion: $0.1 = 1 credit)
- [x] Replace hardcoded `model.cost_per_generation` with `creditsToDeduct`

**Code Location:** After validation, before credit deduction

**Acceptance Criteria:**
- ✅ Calculates cost based on pricing_type
- ✅ Uses duration for per_second pricing
- ✅ Converts dollars to credits correctly

---

### Task 2.6: Update FalAI API Call to Use Dynamic Settings ✅

**File:** `RendioAI/supabase/functions/generate-video/index.ts`

**What to do:**
- [x] Build `finalSettings` using:
  - User's settings OR
  - Model's `required_fields.settings.default` OR
  - Hardcoded defaults
- [x] Pass `finalSettings` to `submitFalAIJob`
- [x] Use user's `prompt` (not theme's prompt)

**Code Location:** Around line 220-234

**Acceptance Criteria:**
- ✅ Settings use defaults from model if not provided
- ✅ User's prompt is sent to FalAI
- ✅ Settings validated before API call

---

### Task 2.7: Test Backend Endpoint ✅

**What to do:**
- [x] Test with Postman or curl:
  - Send request with `theme_id`
  - Verify active model is fetched
  - Verify theme is fetched
  - Verify cost calculation works
  - Verify validation works
- [x] Test error cases:
  - No active model
  - Theme not found
  - Missing required fields
  - Invalid settings

**Acceptance Criteria:**
- ✅ All test cases pass
- ✅ Error handling works correctly

**Test Results:**
- ✅ 4 seconds: 4 credits deducted successfully
- ✅ 8 seconds: 8 credits deducted successfully
- ✅ Idempotency: Working correctly
- ✅ Credit system: 30 → 14 credits (16 credits used correctly)

---

## 🎨 Phase 3: Frontend Updates

### Task 3.1: Create Theme Model ✅

**File:** `RendioAI/RendioAI/Core/Models/Theme.swift` (NEW)

**What to do:**
- [x] Create new file
- [x] Define `Theme` struct with all fields
- [x] Add `CodingKeys` for snake_case conversion
- [x] Make it `Identifiable` and `Codable`

**Acceptance Criteria:**
- ✅ File created
- ✅ Compiles without errors
- ✅ Matches database schema

---

### Task 3.2: Create ModelRequirements Model ✅

**File:** `RendioAI/RendioAI/Core/Models/ModelRequirements.swift` (NEW)

**What to do:**
- [x] Create new file
- [x] Define nested structs:
  - `ModelRequirements`
  - `SettingsConfig`
  - `FieldConfig`
  - `DurationConfig`
- [x] Add `CodingKeys` for snake_case conversion
- [x] Make it `Codable`

**Acceptance Criteria:**
- ✅ File created
- ✅ Compiles without errors
- ✅ Matches JSONB structure from database

---

### Task 3.3: Update ModelDetail Model ✅

**File:** `RendioAI/RendioAI/Core/Models/ModelDetail.swift`

**What to do:**
- [x] Add `requiredFields: ModelRequirements?` property
- [x] Add to `CodingKeys`: `case requiredFields = "required_fields"`
- [x] Update initializers if needed

**Acceptance Criteria:**
- ✅ Compiles without errors
- ✅ Can decode `required_fields` from API

---

### Task 3.4: Create ThemeService ✅

**File:** `RendioAI/RendioAI/Core/Networking/ThemeService.swift` (NEW)

**What to do:**
- [x] Create new file
- [x] Define `ThemeServiceProtocol`
- [x] Implement `ThemeService` class
- [x] Add `fetchThemes()` method
- [x] Add `fetchThemeDetail(id:)` method
- [x] Use same pattern as `ModelService`

**Acceptance Criteria:**
- ✅ File created
- ✅ Can fetch themes from database
- ✅ Can fetch single theme detail
- ✅ Error handling works

---

### Task 3.5: Update ModelService - Add fetchActiveModel ✅

**File:** `RendioAI/RendioAI/Core/Networking/ModelService.swift`

**What to do:**
- [x] Add `fetchActiveModel()` method to protocol
- [x] Implement method:
  - Query: `models?is_active=eq.true&is_available=eq.true&select=...`
  - Include `required_fields` in select
  - Return `ModelDetail`
- [x] Add error handling

**Acceptance Criteria:**
- ✅ Method added to protocol
- ✅ Implementation works
- ✅ Returns active model with required_fields

---

### Task 3.6: Update HomeViewModel ✅

**File:** `RendioAI/RendioAI/Features/Home/HomeViewModel.swift`

**What to do:**
- [x] Replace `ModelServiceProtocol` with `ThemeServiceProtocol`
- [x] Change `featuredModels` to `featuredThemes: [Theme]`
- [x] Change `allModels` to `allThemes: [Theme]`
- [x] Update `loadData()` to fetch themes instead of models
- [x] Update `filteredModels` computed property to `filteredThemes`

**Acceptance Criteria:**
- ✅ Compiles without errors
- ✅ Fetches themes successfully
- ✅ Filters themes correctly

---

### Task 3.7: Update HomeView ✅

**File:** `RendioAI/RendioAI/Features/Home/HomeView.swift`

**What to do:**
- [x] Replace `selectedModelId` with `selectedThemeId`
- [x] Update carousel to use `viewModel.featuredThemes`
- [x] Update grid to use `viewModel.filteredThemes`
- [x] Update navigation: `ModelDetailView(themeId: selectedThemeId)`
- [x] Update card components to use `Theme` instead of `ModelPreview`

**Acceptance Criteria:**
- ✅ Compiles without errors
- ✅ Shows themes in carousel
- ✅ Shows themes in grid
- ✅ Navigation works

---

### Task 3.8: Update ModelDetailViewModel ✅

**File:** `RendioAI/RendioAI/Features/ModelDetail/ModelDetailViewModel.swift`

**What to do:**
- [x] Change `modelId: String` to `themeId: String`
- [x] Add `theme: Theme?` published property
- [x] Add `activeModel: ModelDetail?` published property
- [x] Add `themeService: ThemeServiceProtocol`
- [x] Update `loadModelDetail()`:
  - Fetch theme and active model in parallel
  - Pre-fill `prompt` from theme
  - Apply theme's default settings
- [x] Update `generateVideo()`:
  - Send `theme_id` instead of `model_id`
  - Send user's `prompt` (may be modified)

**Acceptance Criteria:**
- ✅ Compiles without errors
- ✅ Fetches theme and active model
- ✅ Pre-fills prompt from theme
- ✅ User can modify prompt
- ✅ Sends correct data to backend

---

### Task 3.9: Update ModelDetailView ✅

**File:** `RendioAI/RendioAI/Features/ModelDetail/ModelDetailView.swift`

**What to do:**
- [x] Change `modelId: String` to `themeId: String`
- [x] Update initializer
- [x] Update header to show theme name (or active model name)
- [x] Update description section to show theme description
- [x] Keep prompt input (pre-filled from theme)
- [x] Replace `SettingsPanel` with `DynamicSettingsPanel`

**Acceptance Criteria:**
- ✅ Compiles without errors
- ✅ Shows theme information
- ✅ Prompt is pre-filled
- ✅ Settings panel is dynamic

---

### Task 3.10: Create DynamicSettingsPanel ✅

**File:** `RendioAI/RendioAI/Features/ModelDetail/Components/DynamicSettingsPanel.swift` (NEW)

**What to do:**
- [x] Create new file
- [x] Copy structure from `SettingsPanel`
- [x] Add `requiredFields: ModelRequirements?` parameter
- [x] Show settings conditionally based on `requiredFields`
- [x] Use options from `requiredFields.settings`
- [x] Apply defaults from `requiredFields.settings`

**Acceptance Criteria:**
- ✅ File created
- ✅ Shows only required settings
- ✅ Uses correct options
- ✅ Applies defaults correctly

---

### Task 3.11: Update VideoGenerationRequest ✅

**File:** `RendioAI/RendioAI/Core/Models/VideoGenerationRequest.swift`

**What to do:**
- [x] Replace `model_id: String` with `theme_id: String`
- [x] Update `CodingKeys`
- [x] Update preview data

**Acceptance Criteria:**
- ✅ Compiles without errors
- ✅ Matches backend interface

---

## 🧪 Phase 4: Testing

### Task 4.1: Test Theme Fetching ✅

**What to do:**
- [x] Run app
- [x] Verify HomeView shows themes (not models)
- [x] Verify carousel shows featured themes
- [x] Verify grid shows all themes
- [x] Check console logs for API calls

**Acceptance Criteria:**
- ✅ Themes display correctly
- ✅ No errors in console

---

### Task 4.2: Test Prompt Pre-filling ✅

**What to do:**
- [x] Tap a theme in HomeView
- [x] Verify ModelDetailView opens
- [x] Verify prompt field is pre-filled with theme's prompt
- [x] Verify user can edit the prompt

**Acceptance Criteria:**
- ✅ Prompt is pre-filled
- ✅ User can modify prompt

---

### Task 4.3: Test Dynamic Settings ✅

**What to do:**
- [x] Open ModelDetailView
- [x] Verify settings panel shows correct options
- [x] Verify options match active model's `required_fields`
- [x] Test changing settings
- [x] Verify defaults are applied

**Acceptance Criteria:**
- ✅ Settings panel shows correct fields
- ✅ Options match model requirements
- ✅ Defaults work correctly

---

### Task 4.4: Test Video Generation with Modified Prompt ✅

**What to do:**
- [x] Open a theme
- [x] Modify the prompt
- [x] Adjust settings
- [x] Tap Generate
- [x] Verify backend receives modified prompt (check logs)
- [x] Verify video generation starts

**Acceptance Criteria:**
- ✅ Modified prompt is sent to backend
- ✅ Video generation works
- ✅ Backend uses user's prompt (not theme's)

---

### Task 4.5: Test Cost Calculation ✅

**What to do:**
- [x] Generate video with different durations
- [x] Verify cost changes for per_second pricing
- [x] Check credit deduction is correct
- [x] Verify cost matches: `base_price * duration * 100` (for credits)

**Acceptance Criteria:**
- ✅ Cost calculated correctly
- ✅ Credits deducted correctly

---

### Task 4.6: Test Validation ✅

**What to do:**
- [x] Test missing prompt (if required)
- [x] Test missing image_url (if required)
- [x] Test invalid duration
- [x] Test invalid aspect_ratio
- [x] Verify error messages are clear

**Acceptance Criteria:**
- ✅ Validation works correctly
- ✅ Error messages are helpful

---

## 📝 Notes

- **Order Matters:** Complete Phase 1 (Database) before Phase 2 (Backend), and Phase 2 before Phase 3 (Frontend)
- **Testing:** Test each phase before moving to the next
- **Reference:** See `THEMES_AND_MODELS_ARCHITECTURE_PLAN.md` for detailed specifications
- **Breaking Changes:** This will break existing functionality until all phases are complete

---

## ✅ Completion Checklist

- [x] Phase 1: Database Setup (Tasks 1.1 - 1.3) ✅ COMPLETE
- [x] Phase 2: Backend Updates (Tasks 2.1 - 2.7) ✅ COMPLETE
- [x] Phase 3: Frontend Updates (Tasks 3.1 - 3.11) ✅ COMPLETE
- [x] Phase 4: Testing (Tasks 4.1 - 4.6) ✅ COMPLETE

**🎉 ALL PHASES COMPLETE - PROJECT FULLY IMPLEMENTED AND TESTED 🎉**

---

**End of Todo List**

