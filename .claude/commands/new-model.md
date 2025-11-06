# Create Data Model with RLS

You are creating a data model for Rendio AI with proper Codable conformance and RLS policies.

## Instructions

Ask the user:
1. **Model name** (e.g., "VideoJob", "UserCredits", "Model")
2. **Purpose** (what data it represents)
3. **Properties** (fields and types)
4. **Relationships** (foreign keys, if any)
5. **Access rules** (who can read/write)

Then create:

### 1. Swift Model File

Location: `Core/Models/{ModelName}.swift`

```swift
import Foundation

struct {ModelName}: Codable, Identifiable {
    // MARK: - Properties
    let id: UUID
    let createdAt: Date
    // ... other properties

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        // Snake case mapping
    }
}

// MARK: - Convenience
extension {ModelName} {
    static var preview: {ModelName} {
        // Preview data for SwiftUI previews
    }
}
```

### Requirements
- ✅ `Codable` conformance for JSON
- ✅ `Identifiable` if used in Lists/ForEach
- ✅ `CodingKeys` for snake_case mapping
- ✅ Preview data for SwiftUI
- ✅ Optional properties properly handled

### 2. Database Table Schema

SQL migration file: `supabase/migrations/{timestamp}_create_{table_name}.sql`

```sql
-- Create table
CREATE TABLE IF NOT EXISTS public.{table_name} (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Additional columns
);

-- Enable RLS
ALTER TABLE public.{table_name} ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own records"
ON public.{table_name}
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own records"
ON public.{table_name}
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own records"
ON public.{table_name}
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own records"
ON public.{table_name}
FOR DELETE
USING (auth.uid() = user_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS {table_name}_user_id_idx
ON public.{table_name}(user_id);

CREATE INDEX IF NOT EXISTS {table_name}_created_at_idx
ON public.{table_name}(created_at DESC);

-- Updated_at trigger
CREATE TRIGGER update_{table_name}_updated_at
BEFORE UPDATE ON public.{table_name}
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

### 3. RLS Policy Patterns

Choose appropriate policy:

**User-owned data:**
```sql
USING (auth.uid() = user_id)
```

**Guest users (device-based):**
```sql
USING (
  auth.uid() = user_id OR
  device_id = current_setting('request.jwt.claims', true)::json->>'device_id'
)
```

**Public read, private write:**
```sql
-- Read: anyone
FOR SELECT USING (true);

-- Write: owner only
FOR INSERT WITH CHECK (auth.uid() = user_id);
```

**Admin only:**
```sql
USING (
  auth.jwt()->>'role' = 'admin'
)
```

### 4. Service Layer Method

Add to appropriate service in `Core/Networking/`:

```swift
extension {ServiceName} {
    func fetch{ModelName}s() async throws -> [{ModelName}] {
        let response: [{ModelName}] = try await supabase
            .from("{table_name}")
            .select()
            .execute()
            .value

        return response
    }

    func create{ModelName}(_ model: {ModelName}) async throws -> {ModelName} {
        let response: {ModelName} = try await supabase
            .from("{table_name}")
            .insert(model)
            .select()
            .single()
            .execute()
            .value

        return response
    }
}
```

### 5. Error Handling

Add to `AppError` enum if new error types needed:

```swift
enum AppError: Error {
    // Existing cases...
    case {modelName}NotFound
    case invalid{ModelName}Data
}
```

## Output

Provide:
1. **Swift model file** (complete)
2. **SQL migration** (table + RLS policies)
3. **Service methods** (CRUD operations)
4. **Usage example** in ViewModel
5. **Testing queries** (SQL to verify RLS)

Include explanations of:
- Why specific RLS policies were chosen
- Performance considerations (indexes)
- Security implications
