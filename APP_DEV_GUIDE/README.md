# App Development Guide - RendioAI

A comprehensive, modular guide for building production-ready iOS apps with SwiftUI and Supabase.

## 📁 Guide Structure

This guide is organized into focused, manageable sections:

### 1. iOS Architecture
**Path:** `1-iOS-Architecture/`

Covers frontend architecture patterns, code organization, and SwiftUI best practices.

- **[MVVM Pattern](1-iOS-Architecture/01-MVVM-Pattern.md)** - Model-View-ViewModel architecture
- **[Project Structure](1-iOS-Architecture/02-Project-Structure.md)** - How to organize your Xcode project
- **[Service Layer](1-iOS-Architecture/03-Service-Layer.md)** - Business logic and service protocols
- **[Networking Layer](1-iOS-Architecture/04-Networking-Layer.md)** - API client architecture
- **[State Management](1-iOS-Architecture/05-State-Management.md)** - Managing app state with Combine
- **[Error Handling](1-iOS-Architecture/06-Error-Handling.md)** - Centralized error management
- **[Navigation Patterns](1-iOS-Architecture/07-Navigation-Patterns.md)** - SwiftUI navigation best practices

### 2. Backend Architecture
**Path:** `2-Backend-Architecture/`

Covers Supabase backend design, database architecture, and API patterns.

- **[Database Schema](2-Backend-Architecture/01-Database-Schema.md)** - Table design and relationships
- **[Stored Procedures](2-Backend-Architecture/02-Stored-Procedures.md)** - Atomic operations and business logic
- **[Row-Level Security](2-Backend-Architecture/03-Row-Level-Security.md)** - RLS policies and access control
- **[Edge Functions](2-Backend-Architecture/04-Edge-Functions.md)** - API endpoint architecture
- **[Storage Buckets](2-Backend-Architecture/05-Storage-Buckets.md)** - File storage and policies
- **[Credit System](2-Backend-Architecture/06-Credit-System.md)** - Atomic credit operations
- **[Idempotency](2-Backend-Architecture/07-Idempotency.md)** - Preventing duplicate operations

### 3. Integration Examples
**Path:** `3-Integration-Examples/`

Real-world examples of iOS-Backend integration.

- **[Authentication Flow](3-Integration-Examples/01-Authentication-Flow.md)** - DeviceCheck + Anonymous auth
- **[Video Generation](3-Integration-Examples/02-Video-Generation-Flow.md)** - End-to-end generation flow
- **[Credit Purchase](3-Integration-Examples/03-Credit-Purchase-Flow.md)** - In-App Purchase integration
- **[Real-time Updates](3-Integration-Examples/04-Realtime-Updates.md)** - Supabase Realtime subscriptions
- **[Error Scenarios](3-Integration-Examples/05-Error-Scenarios.md)** - Handling failures gracefully

### 4. Configuration
**Path:** `4-Configuration/`

Environment setup and configuration management.

- **[Environment Setup](4-Configuration/01-Environment-Setup.md)** - Dev vs. Production configs
- **[Build Schemes](4-Configuration/02-Build-Schemes.md)** - Xcode schemes and configurations
- **[API Keys Management](4-Configuration/03-API-Keys-Management.md)** - Secure key storage
- **[Feature Flags](4-Configuration/04-Feature-Flags.md)** - Controlling features per environment

### 5. Code Templates
**Path:** `5-Code-Templates/`

Ready-to-use code templates for common patterns.

- **[ViewModel Template](5-Code-Templates/01-ViewModel-Template.swift)** - Standard ViewModel structure
- **[Service Template](5-Code-Templates/02-Service-Template.swift)** - Service protocol + implementation
- **[API Client Template](5-Code-Templates/03-APIClient-Template.swift)** - Network request wrapper
- **[Model Template](5-Code-Templates/04-Model-Template.swift)** - Codable model with CodingKeys
- **[View Template](5-Code-Templates/05-View-Template.swift)** - SwiftUI View structure
- **[Edge Function Template](5-Code-Templates/06-EdgeFunction-Template.ts)** - Supabase Edge Function
- **[RLS Policy Template](5-Code-Templates/07-RLS-Policy-Template.sql)** - Row-Level Security policy

---

## 🎯 How to Use This Guide

### For New Projects
1. Start with **Project Structure** to set up your Xcode project
2. Read **MVVM Pattern** to understand the architecture
3. Use **Code Templates** as starting points for new features
4. Follow **Database Schema** to design your backend
5. Reference **Integration Examples** when connecting iOS to backend

### For Existing Projects
1. Compare your architecture with **iOS Architecture** section
2. Improve error handling using **Error Handling** guide
3. Add missing security with **Row-Level Security** guide
4. Optimize performance with **Backend Architecture** patterns

### For Code Reviews
1. Check adherence to **MVVM Pattern**
2. Verify security with **Row-Level Security** checklist
3. Ensure atomic operations using **Stored Procedures**
4. Validate error handling against **Error Handling** guide

### For Onboarding New Developers
1. Read **README.md** (this file) for overview
2. Study **MVVM Pattern** and **Project Structure**
3. Review **Integration Examples** to see how pieces connect
4. Use **Code Templates** when implementing new features

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS App (SwiftUI)                    │
├─────────────────────────────────────────────────────────────┤
│  Views (SwiftUI)                                            │
│    ↕                                                        │
│  ViewModels (Business Logic)                                │
│    ↕                                                        │
│  Services (Domain Logic)                                    │
│    ↕                                                        │
│  Networking Layer (API Client)                              │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS (JWT Auth)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Backend                         │
├─────────────────────────────────────────────────────────────┤
│  Edge Functions (API Endpoints)                             │
│    ↕                                                        │
│  PostgreSQL Database (RLS Enabled)                          │
│    ↕                                                        │
│  Storage Buckets (Videos, Images)                           │
│    ↕                                                        │
│  External Providers (FalAI, Apple IAP, DeviceCheck)         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📚 Key Concepts

### MVVM (Model-View-ViewModel)
- **Model:** Data structures (Codable structs)
- **View:** SwiftUI views (presentation layer)
- **ViewModel:** Business logic, state management (@Published properties)

### Service Layer
- Protocol-based design for testability
- Mock implementations for testing
- Production implementations for real backend calls

### Row-Level Security (RLS)
- Database-level access control
- Policies enforce user data isolation
- Works with JWT tokens (anonymous or authenticated)

### Atomic Operations
- Use stored procedures for credit operations
- Prevent race conditions with row locks
- Automatic rollback on failures

### Idempotency
- Client generates unique request IDs
- Server caches responses for duplicates
- Prevents double-charging on retries

---

## 🔗 Quick Links

- **[Full Checklist](../APP_DEVELOPMENT_CHECKLIST.md)** - Complete development checklist
- **[Project Overview](../RendioAI/docs/active/design/ProjectOverview.md)** - Product vision and features
- **[Production Readiness](../RendioAI/PRODUCTION_READINESS_TESTING_CHECKLIST.md)** - Launch checklist
- **[Data Schema](../RendioAI/docs/active/design/database/data-schema-final.md)** - Complete database schema
- **[API Blueprint](../RendioAI/docs/active/design/backend/api-layer-blueprint.md)** - API specifications

---

## 🎓 Learning Path

### Beginner (Week 1)
1. iOS Architecture → MVVM Pattern
2. iOS Architecture → Project Structure
3. Code Templates → View Template
4. Code Templates → ViewModel Template

### Intermediate (Week 2-3)
1. iOS Architecture → Service Layer
2. iOS Architecture → Networking Layer
3. Backend Architecture → Database Schema
4. Backend Architecture → Edge Functions
5. Integration Examples → Authentication Flow

### Advanced (Week 4+)
1. Backend Architecture → Stored Procedures
2. Backend Architecture → Row-Level Security
3. Backend Architecture → Idempotency
4. Integration Examples → Credit Purchase Flow
5. Integration Examples → Error Scenarios

---

## 💡 Best Practices Highlighted

Throughout this guide, you'll find:

- ✅ **Do This** - Recommended approaches
- ❌ **Don't Do This** - Common mistakes to avoid
- ⚠️ **Warning** - Critical security or performance issues
- 💡 **Tip** - Helpful insights and shortcuts
- 🔒 **Security** - Security-related best practices

---

## 📝 Contributing to This Guide

This guide is based on real production code from RendioAI. As the project evolves:

1. Update relevant sections when architecture changes
2. Add new templates for new patterns
3. Document lessons learned from production issues
4. Keep code examples synchronized with actual codebase

---

## 📞 Support

If you have questions or need clarification on any section:

1. Check the specific guide file in the relevant folder
2. Review the code templates for working examples
3. Refer to the full checklist for step-by-step instructions
4. Consult the original RendioAI codebase for reference

---

**Last Updated:** 2025-11-15

**Version:** 1.0

**Status:** 🚧 In Progress (Building modular documentation)
