# Check Design Compliance

You are verifying design system compliance and Apple HIG adherence for Rendio AI.

## Instructions

Ask the user:
1. **View/Component** to check (file path or code)
2. **Screen context** (which blueprint it implements)

Then audit:

### 1. Color System Audit
Verify semantic color usage:
- ✅ `Color("BrandPrimary")` for primary actions
- ✅ `Color("SurfaceBase")` for backgrounds
- ✅ `Color("SurfaceCard")` for card surfaces
- ✅ `Color("TextPrimary")` for main text
- ✅ `Color("TextSecondary")` for labels
- ✅ `Color("AccentWarning")` for warnings
- ✅ `Color("AccentSuccess")` for success states

❌ Flag hardcoded colors:
- `.blue`, `.purple`, `.gray`
- `Color(hex: "...")` without semantic name
- RGB values

### 2. Typography Hierarchy
Check proper usage:
- ✅ `.largeTitle` (34pt Bold) for page titles
- ✅ `.title2` (22pt Semibold) for sections
- ✅ `.headline` (17pt Semibold) for subsections
- ✅ `.body` (17pt Regular) for content
- ✅ `.caption` (12pt Regular) for metadata

❌ Flag:
- `.font(.system(size: X))` (use semantic modifiers)
- Custom font sizes
- Inconsistent weight usage

### 3. Spacing & Layout
Verify 8pt grid system:
- ✅ Padding: 16pt, 24pt, 32pt
- ✅ Spacing: 8pt, 12pt, 16pt
- ❌ Flag: 15pt, 23pt, irregular values

Check layout structure:
- ✅ `.safeAreaInset()` respected
- ✅ Proper `VStack`/`HStack` spacing
- ✅ Consistent vertical rhythm

### 4. Corner Radius & Shadows
Standard values:
- ✅ 12pt for cards
- ✅ 8pt for buttons
- ✅ Shadow: `.shadow(color: .black.opacity(0.1), radius: 4, y: 2)`

❌ Flag arbitrary values

### 5. Animation Standards
Check:
- ✅ 0.2-0.3s for micro-transitions
- ✅ 0.3-0.4s for screen transitions
- ✅ `.spring(duration: 0.4, bounce: 0.2)`
- ✅ `.snappy` or `.smooth` for iOS 17+

❌ Flag:
- Long animations (> 0.5s)
- No animation on state changes
- Jarring linear animations

### 6. Apple HIG Compliance
Verify:
- ✅ Dynamic Type support
- ✅ VoiceOver labels (accessibility)
- ✅ Safe area insets
- ✅ Native iOS components
- ✅ Standard navigation patterns

### 7. Blueprint Alignment
Compare with design blueprint:
- ✅ Layout structure matches
- ✅ Component hierarchy correct
- ✅ Spacing consistent
- ✅ All required elements present

## Output Format

Provide:
1. **✅ Design Compliant** (what's correct)
2. **⚠️ Minor Issues** (suggestions for improvement)
3. **❌ Design Violations** (must fix)
4. **Refactored Code** (with design tokens applied)
5. **Visual Comparison** (before/after if helpful)

Be specific about exact token names and values to use.
