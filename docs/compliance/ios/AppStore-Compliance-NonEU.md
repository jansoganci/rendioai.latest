## Non‑EU App Store Compliance Checklist (BananaUniverse)

Reference: `https://developer.apple.com/app-store/review/guidelines/#design`


### Scope
- You target all regions EXCEPT the EU. Skip EU-only items noted below.


### 1) Must‑Do Before Submission
- [ ] Test full app: no crashes, obvious bugs, or broken flows
- [ ] Ensure backend/services are live and reachable by App Review
- [ ] Provide demo account or fully featured demo mode + sample artifacts (e.g., QR)
- [ ] Complete and accurate metadata (name, subtitle, description, screenshots, support URL)
- [ ] Add clear Review Notes for any non‑obvious flows and IAPs
- [ ] Update contact info so App Review can reach you
- [ ] App Store Privacy “nutrition labels” match actual collection/usage
- [ ] Export compliance (encryption) questions answered in App Store Connect


### 2) Privacy & Data
- [ ] Privacy Manifest: no “Required Reason APIs” used without valid reason declarations (check SDKs)
- [ ] ATT prompt ONLY if you access IDFA or track across apps/sites; otherwise do not show
- [ ] Usage descriptions are specific and truthful (e.g., `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`, `NSMicrophoneUsageDescription` if applicable)
- [ ] Collect only necessary data; no hidden tracking
- [ ] App Store privacy labels reflect actual data collection and are kept in sync with the app


### 3) UGC & Safety
- [ ] Content reporting: visible “Report” control on generated images
- [ ] Logging + moderation workflow (status: pending → reviewed → actioned)
- [ ] Add “Acceptable Use Policy” link near the report UI; outline prohibited content
- [ ] Optional but recommended: block/mute abusive users after repeated violations
- [ ] Apply minimal server‑side prompt/result safety filters to avoid sexual/violent content surfacing


### 4) Business & IAP
- [ ] Digital goods/services use IAP (no external purchase links/steering)
- [ ] “Restore Purchases” button available (e.g., on paywall and/or settings)
- [ ] If subscriptions are added later: show price, term, auto‑renew info, and a manage‑subscription link
- [ ] Be explicit about credit consumption before generation (confirmation is recommended)


### 5) Sign‑in & Accounts
- [ ] If adding third‑party sign‑in (Google/Facebook), include “Sign in with Apple”
- [ ] In‑app account deletion present if accounts exist
- [ ] Backend deletion removes user data (e.g., `user_credits`, `credit_transactions`, `processed_images`) and revokes tokens


### 6) Design & UX Quality Signals
- [ ] Follow HIG basics (clear hierarchy, accessible controls, adaptive layouts)
- [ ] Accessibility: Dynamic Type, VoiceOver labels on core controls and images
- [ ] Use only `SKStoreReviewController` for ratings (no custom review prompts)
- [ ] Request permissions with context (show “why now” screen before prompting)


### 7) App Review Readiness
- [ ] Provide demo account credentials in App Review Notes (+ sample artifacts if needed)
- [ ] Ensure backend is reachable to reviewers (no region/IP blocks)
- [ ] Explain non‑obvious flows in Review Notes (credit consumption, report system, deletion flow)


### 8) Metadata Accuracy
- [ ] Age Rating questionnaire:
  - Unrestricted Web Access: NO (API usage ≠ general web browsing)
  - User‑Generated Content: YES (AI‑generated images are considered UGC)
  - Mature/Suggestive Themes: NO (ensure filters support this)
- [ ] Description includes AI disclosure and credit/IAP disclosures
- [ ] Screenshots use only safe, representative results and real UI


### 9) Third‑Party Services & SDKs
- [ ] Document SDK data flows (e.g., fal.ai processes images; no tracking)
- [ ] Apple handles IAP; reflect this in privacy policy and support docs
- [ ] Audit SDKs and disable non‑essential data collection


### EU‑Only Items to Skip (since you’re not publishing in EU)
- [ ] Alternative app marketplaces / Web Distribution (iOS/iPadOS Notarization)
- [ ] ASR & NR‑tagged requirements tied to EU alternative distribution


---

## BananaUniverse‑Specific Additions

### Privacy Policy (Required)
Include:
- Data collection: uploaded images, device IDs (anonymous auth), credit transaction history
- Third‑party sharing: fal.ai (image processing), Apple (IAP)
- Data retention: how long images are stored and when deleted
- User rights: data deletion request, revoke consent
- Contact info: support email for privacy questions

Where to add:
- Privacy Policy URL in App Store Connect (App Information)
- Link inside app (Profile/Settings) to Privacy and Terms


### Content Moderation System (Required for UGC)
Core elements:
- Report button on generated images
- Logging mechanism with review statuses
- Clear response process (triage cadence)
- Optional: auto‑block users after repeated violations

Suggested database:
```
content_reports(id, image_id, user_id, reason, status, created_at)
```


### Age Rating (Required)
- Unrestricted Web Access: NO
- User‑Generated Content: YES
- Mature/Suggestive Themes: NO (enforce safety filters)
- Expected overall rating: 9+ or 12+


### In‑App Purchase Disclosures
- Describe credit system and IAPs in the app description
- Show credit costs before generation; include “Restore Purchases”


### Contact Information (Required)
- Support URL in App Store Connect
- In‑app links: “Contact Support”, “FAQ / Help Center”


### AI Content Attribution (Recommended)
- Small “AI‑generated content” label on result views
- AI disclosure in description


### Data Deletion (Required if accounts exist)
- “Delete Account” in settings
- Backend removes user rows and revokes tokens
- Confirmation dialog prior to deletion


---

## Submission Order of Operations

### Before Submission (Critical)
1. Privacy Policy link (App Store Connect + in‑app)
2. Age Rating questionnaire
3. App description with AI/credit/IAP disclosures
4. Support/Contact info present and accurate
5. Privacy labels + privacy manifest + ATT decision finalized
6. “Restore Purchases” wired up and tested

### First Update (High)
1. Content reporting workflow and UI
2. Account deletion end‑to‑end (frontend + backend)

### Nice to Have (Medium)
1. Terms of Service
2. AI attribution labels
3. FAQ/Help center
4. Accessibility pass polish


---

## Quick Privacy Policy Template Pointers

Key points:
- Images you upload (processed by fal.ai, deleted per stated retention policy)
- Device ID for anonymous authentication
- Purchase history via Apple IAP (Apple as processor)
- Data uses: provide AI image processing, manage credits, process IAP
- Third‑party services: fal.ai (processing), Apple (payments)
- Retention: images N hours/days; transactions retained for accounting
- Rights: deletion requests via support email; in‑app account deletion
- Contact: `support@bananauniverse.com`


