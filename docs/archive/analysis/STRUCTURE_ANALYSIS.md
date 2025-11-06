# 📂 Project Structure Analysis — Rendio AI

**Date:** 2025-11-05  
**Scope:** Folder organization and documentation hierarchy

---

## 🔍 Current Structure

```
/
├── README.md
├── RendioAI/                    # iOS source code
├── design/                      # Mixed: blueprints + operational docs
│   ├── ProjectOverview.md       # ← High-level (should be in docs/)
│   ├── Roadmap.md               # ← High-level (should be in docs/)
│   ├── ErrorHandlingGuide.md    # ← Operational (could stay or move)
│   ├── DataRetentionPolicy.md   # ← Operational (could stay or move)
│   ├── MonitoringAndAlerts.md   # ← Operational (could stay or move)
│   ├── app/
│   │   └── AppConfig.md
│   ├── backend/
│   │   └── api_layer_blueprint.md
│   ├── blueprints/              # Screen designs & flows
│   │   ├── home-screen-design.md
│   │   ├── History_Screen_Blueprint.md
│   │   ├── model-detail-screen-blueprint.md
│   │   ├── result-screen-blueprint.md
│   │   ├── Profile_Screen_Blueprint.md
│   │   ├── OnboardingFlowBlueprint.md
│   │   └── navigation-state-flow.md
│   ├── database/
│   │   └── data_schema_final.md
│   └── security/
│       ├── Security_Policies.md
│       └── anonymous_devicecheck_system_draft.md
└── docs/                        # Empty (intended for public docs)
```

---

## ✅ What's Good

1. **Logical categorization** — Clear separation by domain (app, backend, database, security)
2. **Lowercase folder names** — Follows modern conventions
3. **Blueprints organization** — All UI/UX blueprints in dedicated folder
4. **Domain-specific folders** — Security, database, backend are appropriately separated
5. **README.md at root** — Standard placement for quick reference

---

## ⚠️ Issues Identified

### 1. **Semantic Mixing in `/design/`**
   - Contains both **design blueprints** (UI/UX specs) and **operational documentation** (policies, guides)
   - High-level docs (ProjectOverview, Roadmap) are implementation-agnostic but placed in design/

### 2. **Empty `/docs/` Directory**
   - Intended purpose unclear
   - Should contain public-facing, high-level documentation
   - Currently unused, creating confusion

### 3. **Naming Inconsistencies**
   - `home-screen-design.md` (kebab-case)
   - `History_Screen_Blueprint.md` (PascalCase with underscores)
   - `navigation-state-flow.md` (kebab-case)
   - `anonymous_devicecheck_system_draft.md` (snake_case)
   - **Recommendation:** Standardize to kebab-case

### 4. **File Placement Ambiguity**
   - Operational guides (ErrorHandlingGuide, DataRetentionPolicy) could belong in either `/design/` or `/docs/`
   - No clear distinction between "design-time" vs "runtime" documentation

---

## 💡 Recommendation: Two-Tier Structure

### **Principle:**
- **`/docs/`** = Public-facing, high-level, implementation-agnostic documentation
- **`/design/`** = Implementation-specific blueprints, schemas, and technical specs

### **Proposed Structure:**

```
/
├── README.md
├── RendioAI/                    # iOS source code
├── docs/                        # Public-facing documentation
│   ├── ProjectOverview.md
│   ├── Roadmap.md
│   ├── Contributing.md          # (future)
│   └── Architecture.md          # (future high-level overview)
│
└── design/                      # Implementation specs & blueprints
    ├── app/
    │   └── AppConfig.md
    ├── backend/
    │   ├── api-layer-blueprint.md
    │   ├── api-adapter-interface.md     # (if exists)
    │   └── api-response-mapping.md      # (if exists)
    ├── blueprints/              # UI/UX screen specifications
    │   ├── home-screen.md
    │   ├── model-detail-screen.md
    │   ├── result-screen.md
    │   ├── history-screen.md
    │   ├── profile-screen.md
    │   ├── onboarding-flow.md
    │   └── navigation-state-flow.md
    ├── database/
    │   └── data-schema-final.md
    ├── security/
    │   ├── security-policies.md
    │   └── anonymous-devicecheck-system.md
    └── operations/              # New: Runtime operational docs
        ├── error-handling-guide.md
        ├── data-retention-policy.md
        └── monitoring-and-alerts.md
```

---

## 🔄 Migration Plan

### **Files to Move:**

1. **`design/ProjectOverview.md` → `docs/ProjectOverview.md`**
   - High-level product documentation

2. **`design/Roadmap.md` → `docs/Roadmap.md`**
   - Public roadmap for stakeholders

3. **`design/ErrorHandlingGuide.md` → `design/operations/error-handling-guide.md`**
   - Implementation-specific guide

4. **`design/DataRetentionPolicy.md` → `design/operations/data-retention-policy.md`**
   - Backend operational policy

5. **`design/MonitoringAndAlerts.md` → `design/operations/monitoring-and-alerts.md`**
   - Operational monitoring setup

### **Files to Rename (standardize to kebab-case):**

- `History_Screen_Blueprint.md` → `history-screen.md`
- `Profile_Screen_Blueprint.md` → `profile-screen.md`
- `model-detail-screen-blueprint.md` → `model-detail-screen.md`
- `result-screen-blueprint.md` → `result-screen.md`
- `home-screen-design.md` → `home-screen.md`
- `OnboardingFlowBlueprint.md` → `onboarding-flow.md`
- `navigation-state-flow.md` → `navigation-state-flow.md` (already correct)
- `data_schema_final.md` → `data-schema-final.md`
- `Security_Policies.md` → `security-policies.md`
- `anonymous_devicecheck_system_draft.md` → `anonymous-devicecheck-system.md`
- `api_layer_blueprint.md` → `api-layer-blueprint.md`

---

## 📋 Summary

| Aspect | Status | Action |
|--------|--------|--------|
| **Folder structure** | ✅ Logical | Keep, add `/design/operations/` |
| **Semantic separation** | ⚠️ Mixed | Move high-level docs to `/docs/` |
| **Naming convention** | ❌ Inconsistent | Standardize all to kebab-case |
| **`/docs/` usage** | ❌ Empty | Populate with ProjectOverview, Roadmap |
| **Domain organization** | ✅ Good | Keep current subfolders |

---

## ✅ Final Recommendation

**Keep both `/docs/` and `/design/`** with clear separation:

- **`/docs/`** → Public, stakeholder-facing, product-level documentation
- **`/design/`** → Implementation blueprints, technical specs, operational guides

**Benefits:**
- Clear mental model for developers vs. product managers
- Easy to generate public documentation site from `/docs/`
- Technical implementation details isolated in `/design/`
- Scalable as project grows

---

**Next Steps:**
1. Create `/design/operations/` folder
2. Move and rename files per migration plan
3. Update README.md links to reflect new structure
4. Add `.gitignore` patterns if needed
