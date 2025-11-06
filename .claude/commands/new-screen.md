# Create New Screen from Blueprint

You are creating a new screen for Rendio AI based on the design blueprints.

## Instructions

Ask the user which screen blueprint to implement:
- **Home Screen** (model selection, carousel, search)
- **Model Detail Screen** (prompt input, settings, generation)
- **Result Screen** (video playback, share, download)
- **History Screen** (video list, grouped by date)
- **Profile Screen** (credits, settings, account)
- **Custom Screen** (user provides their own design)

Then:

### 1. Review Blueprint
Load the relevant blueprint from `design/blueprints/` and analyze:
- Layout structure
- Component hierarchy
- Data requirements
- Navigation flow
- User interactions

### 2. Create Implementation
Generate:
- **View file** with proper SwiftUI layout
- **ViewModel** with state management
- **Component files** for complex UI elements
- **Navigation hooks** for screen transitions

### 3. Apply Design System
Ensure:
- ✅ Semantic colors from design tokens
- ✅ SF Pro typography hierarchy
- ✅ 8pt grid spacing system
- ✅ Proper corner radius (12pt cards, 8pt buttons)
- ✅ Smooth animations (0.2-0.4s spring)

### 4. Wire Backend
If the screen requires data:
- Identify required API endpoints
- Create service layer calls
- Handle loading/error states
- Map responses to models

### 5. Test Scenarios
Provide test scenarios for:
- Empty state
- Loading state
- Error state
- Success state with data

## Output

Deliver complete, production-ready implementation with:
- Full source code
- Integration instructions
- Any required database/API changes
- Testing checklist
