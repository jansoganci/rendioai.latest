# 🎯 Themes & Models Architecture Plan

**Date:** 2025-11-06  
**Purpose:** Complete plan for transitioning from model-based to theme-based UI with dynamic model selection

---

## 📋 Table of Contents

1. [Current Architecture](#current-architecture)
2. [Proposed Architecture](#proposed-architecture)
3. [Database Changes](#database-changes)
4. [Frontend Changes](#frontend-changes)
5. [Backend Changes](#backend-changes)
6. [User Flow & Prompt Handling](#user-flow--prompt-handling)
7. [Implementation Steps](#implementation-steps)

---

## 🏗️ Current Architecture

### Current Database Structure

**`models` table:**
```sql
- id (UUID)
- name (TEXT) - e.g., "FalAI Veo 3.1"
- category (TEXT) - e.g., "text-to-video"
- description (TEXT)
- cost_per_generation (INTEGER) - Fixed cost per video
- provider (TEXT) - 'fal', 'runway', 'pika'
- provider_model_id (TEXT) - e.g., "fal-ai/veo3.1"
- is_featured (BOOLEAN) - Show in carousel
- is_available (BOOLEAN) - Enable/disable
- thumbnail_url (TEXT)
- created_at (TIMESTAMPTZ)
```

### Current Frontend Flow

1. **HomeView** → Fetches `models` from database via `ModelService`
2. Shows featured models in carousel
3. Shows all models in grid
4. User taps model → **ModelDetailView**
5. **ModelDetailView**:
   - Shows model description
   - Empty prompt input (user types from scratch)
   - Settings panel (duration, resolution, aspect_ratio)
   - Generate button
6. User generates → Sends `model_id` + `prompt` + `settings` to backend

### Current Backend Flow

1. **`generate-video` endpoint** receives:
   ```typescript
   {
     user_id: string
     model_id: string  // UUID from models table
     prompt: string    // User-typed prompt
     image_url?: string
     settings?: { resolution, aspect_ratio, duration }
   }
   ```
2. Backend:
   - Fetches model from `models` table using `model_id`
   - Validates `image_url` if model requires it (hardcoded check for Sora 2)
   - Deducts credits using `model.cost_per_generation`
   - Calls FalAI API with model's `provider_model_id`
   - Creates `video_jobs` record

### Current Limitations

- ❌ Models are hardcoded in frontend (must update app to add/remove)
- ❌ Fixed pricing per model (can't handle per-second pricing)
- ❌ No way to define model requirements dynamically
- ❌ No themes/vibes system
- ❌ User must type prompts from scratch (no templates)

---

## 🎨 Proposed Architecture

### New Concept: Two-Table System

1. **`models` table** → Technical AI model metadata (backend uses this)
2. **`themes` table** → User-facing content/vibes (frontend displays this)

### New Flow

1. **HomeView** → Fetches `themes` from database (not models)
2. Shows featured themes in carousel (Christmas, Thanksgiving, etc.)
3. User taps theme → **ModelDetailView** (now ThemeDetailView)
4. **ModelDetailView**:
   - Shows theme's default prompt (pre-filled, editable)
   - Shows settings based on **active model's** `required_fields`
   - User can modify prompt and settings
   - Generate button
5. User generates → Sends `theme_id` + `user_prompt` (modified) + `settings` to backend
6. **Backend**:
   - Gets active model: `SELECT * FROM models WHERE is_active = true`
   - Gets theme: `SELECT * FROM themes WHERE id = theme_id`
   - Uses theme's prompt OR user's modified prompt
   - Validates settings against model's `required_fields`
   - Calculates cost dynamically (per_second or per_video)
   - Generates video

---

## 🗄️ Database Changes

### 1. Update `models` Table

**Add new columns:**

```sql
ALTER TABLE models 
ADD COLUMN pricing_type TEXT CHECK (pricing_type IN ('per_second', 'per_video')),
ADD COLUMN base_price NUMERIC(10,2),
ADD COLUMN has_audio BOOLEAN,
ADD COLUMN is_active BOOLEAN DEFAULT false,
ADD COLUMN required_fields JSONB DEFAULT '{}';
```

**Column Descriptions:**

| Column | Type | Purpose | Example |
|--------|------|---------|---------|
| `pricing_type` | TEXT | Pricing model | `'per_second'` or `'per_video'` |
| `base_price` | NUMERIC(10,2) | Base price in dollars | `0.15` (for $0.15/second) |
| `has_audio` | BOOLEAN | Model supports audio | `true` or `false` |
| `is_active` | BOOLEAN | Only ONE model active at a time | `true` = this model is used |
| `required_fields` | JSONB | What fields this model needs | See JSON structure below |

**`required_fields` JSONB Structure:**

```json
{
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
    },
    "audio": {
      "required": false,
      "default": false,
      "options": [false]
    }
  }
}
```

**Example: Sora 2 Model**

```sql
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
  true
);
```

### 2. Create `themes` Table

**New table structure:**

```sql
CREATE TABLE themes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,                    -- "Christmas Magic", "Thanksgiving Feast"
    description TEXT,                      -- Theme description for users
    thumbnail_url TEXT,                     -- Image for carousel/grid
    prompt TEXT NOT NULL,                  -- Default prompt for this theme
    is_featured BOOLEAN DEFAULT false,     -- Show in carousel
    is_available BOOLEAN DEFAULT true,      -- Enable/disable theme
    default_settings JSONB DEFAULT '{}',   -- Default settings for this theme
    created_at TIMESTAMPTZ DEFAULT now()
);
```

**Column Descriptions:**

| Column | Type | Purpose | Example |
|--------|------|---------|---------|
| `id` | UUID | Primary key | Auto-generated |
| `name` | TEXT | Theme name | `"Christmas Magic"` |
| `description` | TEXT | Theme description | `"Create festive holiday videos"` |
| `thumbnail_url` | TEXT | Theme image URL | `"https://cdn.../christmas.jpg"` |
| `prompt` | TEXT | Default prompt | `"A cozy Christmas scene with snow..."` |
| `is_featured` | BOOLEAN | Show in carousel | `true` = appears in featured carousel |
| `is_available` | BOOLEAN | Enable/disable | `false` = hidden from users |
| `default_settings` | JSONB | Default settings | `{"duration": 8, "aspect_ratio": "16:9"}` |
| `created_at` | TIMESTAMPTZ | Creation timestamp | Auto-generated |

**Example Themes:**

```sql
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
);
```

**Indexes:**

```sql
CREATE INDEX idx_themes_featured ON themes(is_featured) WHERE is_featured = true;
CREATE INDEX idx_themes_available ON themes(is_available) WHERE is_available = true;
```

**RLS Policies:**

```sql
ALTER TABLE themes ENABLE ROW LEVEL SECURITY;

-- Anyone can view available themes
CREATE POLICY "Anyone can view available themes"
ON themes FOR SELECT
USING (is_available = true);

-- Only backend (service_role) can modify themes
-- No INSERT/UPDATE/DELETE policies for users
```

---

## 🎨 Frontend Changes

### 1. Create New Models

**`Theme.swift`** (new file):
```swift
struct Theme: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let thumbnailURL: URL?
    let prompt: String
    let isFeatured: Bool
    let defaultSettings: VideoSettings?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, prompt
        case thumbnailURL = "thumbnail_url"
        case isFeatured = "is_featured"
        case defaultSettings = "default_settings"
    }
}
```

**`ModelRequirements.swift`** (new file):
```swift
struct ModelRequirements: Codable {
    let requiresPrompt: Bool
    let requiresImage: Bool
    let requiresSettings: Bool
    let settings: SettingsConfig?
    
    struct SettingsConfig: Codable {
        let resolution: FieldConfig?
        let aspectRatio: FieldConfig?
        let duration: DurationConfig?
        let audio: FieldConfig?
        
        enum CodingKeys: String, CodingKey {
            case resolution, aspectRatio = "aspect_ratio", duration, audio
        }
    }
    
    struct FieldConfig: Codable {
        let required: Bool
        let `default`: String?
        let options: [String]
    }
    
    struct DurationConfig: Codable {
        let required: Bool
        let `default`: Int
        let options: [Int]
    }
    
    enum CodingKeys: String, CodingKey {
        case requiresPrompt = "requires_prompt"
        case requiresImage = "requires_image"
        case requiresSettings = "requires_settings"
        case settings
    }
}
```

**Update `ModelDetail.swift`** to include `requiredFields`:
```swift
struct ModelDetail: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let description: String?
    let thumbnailURL: URL?
    let isFeatured: Bool
    let costPerGeneration: Int?
    let requiredFields: ModelRequirements?  // NEW
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, description
        case thumbnailURL = "thumbnail_url"
        case isFeatured = "is_featured"
        case costPerGeneration = "cost_per_generation"
        case requiredFields = "required_fields"
    }
}
```

### 2. Create ThemeService

**`ThemeService.swift`** (new file):
```swift
protocol ThemeServiceProtocol {
    func fetchThemes() async throws -> [Theme]
    func fetchThemeDetail(id: String) async throws -> Theme
}

class ThemeService: ThemeServiceProtocol {
    static let shared = ThemeService()
    
    private let baseURL = "https://ojcnjxzctnwbmupggoxq.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchThemes() async throws -> [Theme] {
        // Fetch only available themes
        guard let url = URL(string: "\(baseURL)/rest/v1/themes?is_available=eq.true&select=id,name,description,thumbnail_url,prompt,is_featured,default_settings&order=is_featured.desc,name.asc") else {
            throw AppError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkFailure
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode([Theme].self, from: data)
    }
    
    func fetchThemeDetail(id: String) async throws -> Theme {
        guard let url = URL(string: "\(baseURL)/rest/v1/themes?id=eq.\(id)&select=*") else {
            throw AppError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkFailure
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let themes = try decoder.decode([Theme].self, from: data)
        guard let theme = themes.first else {
            throw AppError.invalidResponse
        }
        
        return theme
    }
}
```

### 3. Update HomeView & HomeViewModel

**`HomeViewModel.swift`** changes:
```swift
@Published var featuredThemes: [Theme] = []  // Changed from featuredModels
@Published var allThemes: [Theme] = []       // Changed from allModels

private let themeService: ThemeServiceProtocol  // Changed from modelService

func loadData() {
    Task {
        isLoading = true
        do {
            async let themes = themeService.fetchThemes()  // Changed
            async let credits = creditService.fetchCredits()
            
            let (fetchedThemes, fetchedCredits) = try await (themes, credits)
            
            allThemes = fetchedThemes
            featuredThemes = fetchedThemes.filter { $0.isFeatured }  // Changed
            creditsRemaining = fetchedCredits
        } catch {
            handleError(error)
        }
        isLoading = false
    }
}
```

**`HomeView.swift`** changes:
- Replace `ModelPreview` with `Theme`
- Replace `selectedModelId` with `selectedThemeId`
- Update carousel to show themes
- Update grid to show themes
- Navigation: `ModelDetailView(themeId: selectedThemeId)` instead of `modelId`

### 4. Update ModelDetailView & ModelDetailViewModel

**`ModelDetailView.swift`** changes:
```swift
struct ModelDetailView: View {
    let themeId: String  // Changed from modelId
    let initialPrompt: String?
    
    @StateObject private var viewModel: ModelDetailViewModel
    
    init(themeId: String, initialPrompt: String? = nil) {  // Changed
        self.themeId = themeId
        self.initialPrompt = initialPrompt
        self._viewModel = StateObject(wrappedValue: ModelDetailViewModel(themeId: themeId))
    }
    
    // ... rest of view
}
```

**`ModelDetailViewModel.swift`** changes:
```swift
@MainActor
class ModelDetailViewModel: ObservableObject {
    @Published var theme: Theme?           // NEW: Theme data
    @Published var activeModel: ModelDetail?  // NEW: Active model (for settings)
    @Published var prompt: String = ""     // Pre-filled from theme, editable
    @Published var settings: VideoSettings = .default
    // ... rest
    
    private let themeId: String  // Changed from modelId
    private let themeService: ThemeServiceProtocol  // NEW
    private let modelService: ModelServiceProtocol  // NEW: To get active model
    
    init(themeId: String, ...) {  // Changed
        self.themeId = themeId
        // ... initialize services
    }
    
    func loadModelDetail() {  // Rename to loadThemeAndModel()
        Task {
            isLoading = true
            do {
                // Fetch theme and active model in parallel
                async let fetchedTheme = themeService.fetchThemeDetail(id: themeId)
                async let fetchedModel = modelService.fetchActiveModel()  // NEW method
                async let fetchedCredits = creditService.fetchCredits()
                
                let (themeData, modelData, credits) = try await (fetchedTheme, fetchedModel, fetchedCredits)
                
                theme = themeData
                activeModel = modelData
                creditsRemaining = credits
                
                // Pre-fill prompt from theme
                prompt = themeData.prompt
                
                // Apply theme's default settings if available
                if let defaultSettings = themeData.defaultSettings {
                    settings = defaultSettings
                }
                
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    func generateVideo() {
        // ... validation ...
        
        let request = VideoGenerationRequest(
            user_id: userId,
            theme_id: themeId,  // NEW: Send theme_id instead of model_id
            prompt: prompt.trimmingCharacters(in: .whitespacesAndNewlines),  // User's prompt (may be modified)
            image_url: imageURL,  // NEW: Add image upload support
            settings: settings
        )
        
        // ... rest of generation
    }
}
```

### 5. Update VideoGenerationRequest

**`VideoGenerationRequest.swift`** changes:
```swift
struct VideoGenerationRequest: Codable {
    let user_id: String
    let theme_id: String      // Changed from model_id
    let prompt: String         // User's prompt (may be modified from theme)
    let image_url: String?     // Required for image-to-video models
    let settings: VideoSettings
    
    enum CodingKeys: String, CodingKey {
        case user_id
        case theme_id         // Changed
        case prompt
        case image_url
        case settings
    }
}
```

### 6. Dynamic Settings Panel

**`DynamicSettingsPanel.swift`** (new file):
```swift
struct DynamicSettingsPanel: View {
    @Binding var settings: VideoSettings
    let requiredFields: ModelRequirements?  // From active model
    @State private var isExpanded: Bool = false
    
    var body: some View {
        guard let requiredFields = requiredFields,
              requiredFields.requiresSettings,
              let settingsConfig = requiredFields.settings else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(spacing: 16) {
                    // Show duration if config exists
                    if let durationConfig = settingsConfig.duration {
                        SettingsRow(
                            label: "Duration",
                            value: "\(settings.duration ?? durationConfig.default)s",
                            options: durationConfig.options.map { "\($0)s" },
                            selectedIndex: durationIndex(config: durationConfig)
                        ) { index in
                            settings = VideoSettings(
                                duration: durationConfig.options[index],
                                resolution: settings.resolution,
                                aspect_ratio: settings.aspect_ratio,
                                fps: settings.fps
                            )
                        }
                    }
                    
                    // Show aspect_ratio if config exists
                    if let aspectConfig = settingsConfig.aspectRatio {
                        SettingsRow(
                            label: "Aspect Ratio",
                            value: settings.aspect_ratio ?? aspectConfig.default ?? "auto",
                            options: aspectConfig.options,
                            selectedIndex: aspectIndex(config: aspectConfig)
                        ) { index in
                            settings = VideoSettings(
                                duration: settings.duration,
                                resolution: settings.resolution,
                                aspect_ratio: aspectConfig.options[index],
                                fps: settings.fps
                            )
                        }
                    }
                    
                    // Show resolution if config exists
                    if let resolutionConfig = settingsConfig.resolution {
                        SettingsRow(
                            label: "Resolution",
                            value: settings.resolution ?? resolutionConfig.default ?? "auto",
                            options: resolutionConfig.options,
                            selectedIndex: resolutionIndex(config: resolutionConfig)
                        ) { index in
                            settings = VideoSettings(
                                duration: settings.duration,
                                resolution: resolutionConfig.options[index],
                                aspect_ratio: settings.aspect_ratio,
                                fps: settings.fps
                            )
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(Color("TextPrimary"))
            }
            .padding(16)
            .background(Color("SurfaceCard"))
            .cornerRadius(12)
        )
    }
    
    // Helper methods to find selected index
    private func durationIndex(config: ModelRequirements.SettingsConfig.DurationConfig) -> Int {
        guard let duration = settings.duration,
              let index = config.options.firstIndex(of: duration) else {
            return config.options.firstIndex(of: config.default) ?? 0
        }
        return index
    }
    
    private func aspectIndex(config: ModelRequirements.SettingsConfig.FieldConfig) -> Int {
        let current = settings.aspect_ratio ?? config.default ?? "auto"
        return config.options.firstIndex(of: current) ?? 0
    }
    
    private func resolutionIndex(config: ModelRequirements.SettingsConfig.FieldConfig) -> Int {
        let current = settings.resolution ?? config.default ?? "auto"
        return config.options.firstIndex(of: current) ?? 0
    }
}
```

**Update `ModelDetailView.swift`** to use dynamic panel:
```swift
// Replace SettingsPanel with:
DynamicSettingsPanel(
    settings: $viewModel.settings,
    requiredFields: viewModel.activeModel?.requiredFields
)
```

---

## ⚙️ Backend Changes

### 1. Update `generate-video` Endpoint

**Request Interface Change:**
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

**New Flow in `generate-video/index.ts`:**

```typescript
serve(async (req) => {
  // ... idempotency check ...
  
  const body: GenerateVideoRequest = await req.json()
  const { user_id, theme_id, prompt, image_url, settings } = body
  
  // 1. Get active model (only one active at a time)
  const { data: activeModel, error: modelError } = await supabaseClient
    .from('models')
    .select('id, provider, provider_model_id, pricing_type, base_price, required_fields, is_available')
    .eq('is_active', true)
    .eq('is_available', true)
    .single()
  
  if (modelError || !activeModel) {
    return new Response(
      JSON.stringify({ error: 'No active model found' }),
      { status: 404 }
    )
  }
  
  // 2. Get theme
  const { data: theme, error: themeError } = await supabaseClient
    .from('themes')
    .select('id, prompt, default_settings')
    .eq('id', theme_id)
    .eq('is_available', true)
    .single()
  
  if (themeError || !theme) {
    return new Response(
      JSON.stringify({ error: 'Theme not found' }),
      { status: 404 }
    )
  }
  
  // 3. Validate required fields from model
  const requiredFields = activeModel.required_fields
  
  if (requiredFields.requires_prompt && !prompt) {
    return new Response(
      JSON.stringify({ error: 'prompt is required' }),
      { status: 400 }
    )
  }
  
  if (requiredFields.requires_image && !image_url) {
    return new Response(
      JSON.stringify({ error: 'image_url is required for this model' }),
      { status: 400 }
    )
  }
  
  // 4. Validate settings against model's required_fields
  if (requiredFields.requires_settings && settings) {
    const settingsConfig = requiredFields.settings
    
    if (settings.duration) {
      const allowedDurations = settingsConfig.duration.options
      if (!allowedDurations.includes(settings.duration)) {
        return new Response(
          JSON.stringify({ error: `Invalid duration. Allowed: ${allowedDurations.join(', ')}` }),
          { status: 400 }
        )
      }
    }
    
    // Similar validation for aspect_ratio and resolution
  }
  
  // 5. Calculate cost dynamically
  let costInDollars: number
  if (activeModel.pricing_type === 'per_second') {
    const duration = settings?.duration || requiredFields.settings?.duration?.default || 4
    costInDollars = activeModel.base_price * duration
  } else {
    costInDollars = activeModel.base_price  // per_video
  }
  
  // Convert to credits (direct conversion: $0.1 = 1 credit)
  // Example: $0.1 * 8 seconds = $0.8 = 8 credits
  const creditsToDeduct = costInDollars
  
  // 6. Deduct credits
  const { data: deductResult, error: deductError } = await supabaseClient.rpc('deduct_credits', {
    p_user_id: user_id,
    p_amount: creditsToDeduct,
    p_reason: 'video_generation'
  })
  
  if (deductError || !deductResult?.success) {
    return new Response(
      JSON.stringify({ 
        error: deductResult?.error || 'Insufficient credits',
        credits_remaining: deductResult?.current_credits || 0
      }),
      { status: 402 }
    )
  }
  
  // 7. Create video job
  const { data: job, error: jobError } = await supabaseClient
    .from('video_jobs')
    .insert({
      user_id: user_id,
      model_id: activeModel.id,  // Use active model's ID
      prompt: prompt,  // User's prompt (may be modified from theme)
      settings: settings || theme.default_settings || {},
      status: 'pending',
      credits_used: creditsToDeduct
    })
    .select()
    .single()
  
  if (jobError) {
    // ROLLBACK: Refund credits
    await supabaseClient.rpc('add_credits', {
      p_user_id: user_id,
      p_amount: creditsToDeduct,
      p_reason: 'generation_failed_refund',
      p_transaction_id: null
    })
    
    return new Response(
      JSON.stringify({ error: 'Failed to create job' }),
      { status: 500 }
    )
  }
  
  // 8. Call FalAI API
  try {
    // Apply defaults from model's required_fields
    const finalSettings = {
      resolution: settings?.resolution || requiredFields.settings?.resolution?.default || 'auto',
      aspect_ratio: settings?.aspect_ratio || requiredFields.settings?.aspect_ratio?.default || 'auto',
      duration: (settings?.duration || requiredFields.settings?.duration?.default || 4) as 4 | 8 | 12
    }
    
    const providerResult = await submitFalAIJob(
      activeModel.provider_model_id,
      prompt,  // User's prompt (may be modified)
      image_url!,
      finalSettings
    )
    
    providerJobId = providerResult.request_id
    
    // Update job with provider_job_id
    await supabaseClient
      .from('video_jobs')
      .update({ 
        provider_job_id: providerJobId,
        status: 'processing'
      })
      .eq('job_id', job.job_id)
      
  } catch (providerError) {
    // ROLLBACK: Mark job as failed and refund credits
    await supabaseClient
      .from('video_jobs')
      .update({
        status: 'failed',
        error_message: providerError.message
      })
      .eq('job_id', job.job_id)
    
    await supabaseClient.rpc('add_credits', {
      p_user_id: user_id,
      p_amount: creditsToDeduct,
      p_reason: 'generation_failed_refund',
      p_transaction_id: null
    })
    
    return new Response(
      JSON.stringify({ 
        error: 'Failed to start video generation',
        details: providerError.message
      }),
      { status: 502 }
    )
  }
  
  // 9. Store idempotency record
  // ... (same as before)
  
  return new Response(
    JSON.stringify({
      job_id: job.job_id,
      status: 'pending',
      credits_used: creditsToDeduct
    }),
    { headers: { 'Content-Type': 'application/json' } }
  )
})
```

### 2. Add Method to ModelService (Frontend)

**`ModelService.swift`** - Add method to fetch active model:
```swift
func fetchActiveModel() async throws -> ModelDetail {
    guard let url = URL(string: "\(baseURL)/rest/v1/models?is_active=eq.true&is_available=eq.true&select=id,name,category,description,thumbnail_url,is_featured,cost_per_generation,required_fields") else {
        throw AppError.invalidResponse
    }
    
    // ... fetch and decode ...
    
    guard let model = models.first else {
        throw AppError.invalidResponse
    }
    
    return model
}
```

---

## 🔄 User Flow & Prompt Handling

### Scenario: User Modifies Theme Prompt

1. **User opens app** → HomeView shows themes (Christmas, Thanksgiving, etc.)

2. **User taps "Christmas Magic"** → ModelDetailView opens

3. **ModelDetailView loads:**
   - Fetches theme → Gets default prompt: `"A cozy Christmas scene with snow falling..."`
   - Fetches active model → Gets `required_fields` for settings UI
   - Pre-fills prompt field with theme's prompt
   - Shows settings based on model's `required_fields`

4. **User modifies prompt:**
   - User edits: `"A cozy Christmas scene with snow falling..."` 
   - Changes to: `"A magical winter wonderland with Santa's sleigh flying through the night sky"`
   - This modified prompt is stored in `viewModel.prompt`

5. **User taps Generate:**
   - Frontend sends:
     ```swift
     VideoGenerationRequest(
       user_id: userId,
       theme_id: themeId,  // Still sends theme_id
       prompt: viewModel.prompt,  // User's modified prompt
       image_url: imageURL,
       settings: settings
     )
     ```

6. **Backend receives:**
   - Gets theme (for reference, but doesn't use theme's prompt)
   - Gets active model (for validation and API call)
   - **Uses `prompt` from request** (user's modified prompt)
   - Validates settings against model's `required_fields`
   - Calculates cost dynamically
   - Calls FalAI API with user's prompt

### Key Point: User's Modified Prompt Takes Priority

- ✅ Backend always uses `prompt` from request (user's input)
- ✅ Theme's prompt is only used as default in frontend
- ✅ User can completely change the prompt
- ✅ Backend doesn't need to know if prompt was modified

---

## 📝 Implementation Steps

### Phase 1: Database Setup

1. ✅ Create migration: Add columns to `models` table
   - `pricing_type`, `base_price`, `has_audio`, `is_active`, `required_fields`

2. ✅ Create migration: Create `themes` table
   - All columns as defined above
   - Indexes and RLS policies

3. ✅ Insert test data:
   - One active model (Sora 2) with `required_fields`
   - 3-5 test themes (Christmas, Thanksgiving, Halloween, etc.)

### Phase 2: Backend Updates

1. ✅ Update `generate-video` endpoint:
   - Change request interface to accept `theme_id`
   - Get active model instead of using `model_id`
   - Get theme (for reference)
   - Validate using `required_fields`
   - Calculate cost dynamically
   - Use user's prompt from request

2. ✅ Test backend with Postman/curl

### Phase 3: Frontend Updates

1. ✅ Create new models:
   - `Theme.swift`
   - `ModelRequirements.swift`
   - Update `ModelDetail.swift`

2. ✅ Create `ThemeService.swift`

3. ✅ Update `ModelService.swift`:
   - Add `fetchActiveModel()` method

4. ✅ Update `HomeViewModel` and `HomeView`:
   - Change from models to themes
   - Update carousel and grid

5. ✅ Update `ModelDetailViewModel` and `ModelDetailView`:
   - Accept `themeId` instead of `modelId`
   - Fetch theme and active model
   - Pre-fill prompt from theme
   - Show dynamic settings panel

6. ✅ Update `VideoGenerationRequest`:
   - Change `model_id` to `theme_id`

7. ✅ Create `DynamicSettingsPanel.swift`

### Phase 4: Testing

1. ✅ Test theme fetching
2. ✅ Test prompt pre-filling
3. ✅ Test prompt modification
4. ✅ Test video generation with modified prompt
5. ✅ Test settings validation
6. ✅ Test cost calculation

---

## ✅ Summary

### What Changes:

- **Database:** 
  - `models` table gets new columns for pricing and requirements
  - New `themes` table for user-facing content

- **Frontend:**
  - Shows themes instead of models
  - Pre-fills prompts from themes
  - Dynamic settings based on active model

- **Backend:**
  - Gets active model automatically
  - Uses theme's prompt OR user's modified prompt
  - Validates dynamically based on model requirements

### Benefits:

- ✅ No app updates needed to add/remove themes
- ✅ Dynamic pricing (per_second or per_video)
- ✅ Flexible model requirements
- ✅ User can modify prompts
- ✅ One active model, multiple themes

---

**End of Plan Document**


