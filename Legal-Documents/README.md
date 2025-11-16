# Legal Documents for RendioAI - Complete Package

**Created:** [INSERT DATE]
**Status:** ✅ Ready for Review & Publication

---

## 📁 What's Included

All essential legal and compliance documents for App Store submission:

| Document | Purpose | Status | Required? |
|----------|---------|--------|-----------|
| **PRIVACY_POLICY.md** | User data handling disclosure | ✅ Complete | 🔴 **REQUIRED** |
| **TERMS_OF_SERVICE.md** | Legal agreement with users | ✅ Complete | 🔴 **REQUIRED** |
| **ACCEPTABLE_USE_POLICY.md** | Content guidelines | ✅ Complete | 🔴 **REQUIRED** (UGC apps) |
| **APP_STORE_DESCRIPTION.md** | App Store listing copy | ✅ Complete | 🔴 **REQUIRED** |
| **APP_REVIEW_NOTES.md** | Instructions for Apple reviewers | ✅ Complete | 🔴 **REQUIRED** |
| **SUPPORT_FAQ.md** | User support content | ✅ Complete | 🟡 Recommended |

---

## ⚡ Quick Start Checklist

### Step 1: Review & Customize (2-3 hours)

- [ ] **PRIVACY_POLICY.md**
  - [ ] Replace `[INSERT DATE]` with current date
  - [ ] Replace `support@rendio.ai` with your actual email
  - [ ] Replace `[Your Company Name]` with your company
  - [ ] Replace `[Your Jurisdiction]` with your location
  - [ ] Specify Supabase data region
  - [ ] Review all sections for accuracy

- [ ] **TERMS_OF_SERVICE.md**
  - [ ] Replace all placeholders (dates, company name, emails)
  - [ ] Add your mailing address
  - [ ] Review credit pricing (ensure matches your IAP config)
  - [ ] Customize arbitration clause (or remove if not applicable)

- [ ] **ACCEPTABLE_USE_POLICY.md**
  - [ ] Replace placeholder email addresses
  - [ ] Review prohibited content list
  - [ ] Customize enforcement penalties if desired

- [ ] **APP_STORE_DESCRIPTION.md**
  - [ ] Choose version: Concise (recommended) or Detailed
  - [ ] Customize prompts and examples to match your brand
  - [ ] Verify pricing matches your IAP bundles
  - [ ] Adjust features list based on what's implemented

- [ ] **APP_REVIEW_NOTES.md**
  - [ ] Add demo account credentials (or note guest access)
  - [ ] Verify all technical details are accurate
  - [ ] Add appreview@rendio.ai email or your actual contact

- [ ] **SUPPORT_FAQ.md**
  - [ ] Review all Q&A for accuracy
  - [ ] Add your support email addresses
  - [ ] Customize answers based on your implementation

---

### Step 2: Legal Review (Optional but Recommended)

- [ ] **Hire a lawyer** to review all documents
  - **Cost:** $500-2,000 (varies by location and lawyer)
  - **Time:** 1-2 weeks
  - **Focus areas:**
    - Limitation of liability clauses
    - Arbitration agreements
    - Indemnification
    - Jurisdictional issues
    - GDPR compliance (if targeting EU)
    - COPPA compliance (if children use app)

- [ ] **Alternative:** Use legal services like:
  - LegalZoom
  - Rocket Lawyer
  - Termly (privacy policy generator)

**⚠️ Important:** These templates are comprehensive but NOT legal advice. A lawyer can customize for your specific situation.

---

### Step 3: Publish Online (1-2 hours)

Create pages on your website:

- [ ] **https://rendio.ai/privacy** → PRIVACY_POLICY.md
- [ ] **https://rendio.ai/terms** → TERMS_OF_SERVICE.md
- [ ] **https://rendio.ai/acceptable-use** → ACCEPTABLE_USE_POLICY.md
- [ ] **https://rendio.ai/support** or **https://rendio.ai/faq** → SUPPORT_FAQ.md

**Requirements:**
- Pages must be publicly accessible (no login required)
- Use HTTPS
- Mobile-friendly (responsive design)
- Easy to read (simple HTML or markdown)

**Quick option:** Use GitHub Pages, Notion, or Google Sites for free hosting

---

### Step 4: Add to App Store Connect (30 min)

#### App Information
- [ ] **Privacy Policy URL:** https://rendio.ai/privacy
- [ ] **Support URL:** https://rendio.ai/support
- [ ] **Marketing URL:** https://rendio.ai (optional)

#### App Description
- [ ] Paste from APP_STORE_DESCRIPTION.md
- [ ] Add keywords
- [ ] Set age rating: **12+**

#### App Privacy
- [ ] Configure Privacy Labels based on PRIVACY_POLICY.md
- [ ] Match exactly what's described in policy

#### App Review Information
- [ ] Paste relevant sections from APP_REVIEW_NOTES.md
- [ ] Add demo account info (or note guest access)
- [ ] Add contact email: appreview@rendio.ai

---

### Step 5: Add to iOS App (1 hour)

In your ProfileView or SettingsView:

```swift
// Links to legal documents
Link("Privacy Policy", destination: URL(string: "https://rendio.ai/privacy")!)
Link("Terms of Service", destination: URL(string: "https://rendio.ai/terms")!)
Link("Acceptable Use", destination: URL(string: "https://rendio.ai/acceptable-use")!)
Link("Support & FAQ", destination: URL(string: "https://rendio.ai/faq")!)
```

**Best practice:** Open links in Safari (or SFSafariViewController) for transparency.

---

## 📊 Document Breakdown

### 1. Privacy Policy (9,000+ words)

**What it covers:**
- Data collection (what, why, how)
- Third-party sharing (FalAI, Apple, Supabase)
- Data retention (7-day videos, transaction logs)
- User rights (access, delete, export)
- Security measures (encryption, RLS)
- Children's privacy (13+ requirement)
- International transfers (GDPR compliance)
- Contact information

**Key sections:**
- Complete data inventory
- Third-party disclosures
- 7-day retention policy
- Account deletion process
- GDPR-ready language

**Format:** Markdown (convert to HTML for website)

---

### 2. Terms of Service (7,500+ words)

**What it covers:**
- Description of service (AI video generation)
- Account authentication (guest + Apple Sign-In)
- Credit system (pricing, refunds, limitations)
- Content ownership (you own generated videos)
- Acceptable use (what's prohibited)
- Content moderation (reporting, enforcement)
- Disclaimers (AI limitations, "as is" service)
- Limitation of liability
- Dispute resolution (arbitration)

**Key sections:**
- AI content disclaimer
- Credit system rules
- Prohibited content
- Indemnification clause
- Governing law

**Format:** Markdown (convert to HTML)

---

### 3. Acceptable Use Policy (5,000+ words)

**What it covers:**
- Prohibited content (10 categories)
- Prohibited behaviors (4 categories)
- AI-specific guidelines
- Enforcement (penalties, appeals)
- Reporting violations
- Copyright/trademark procedures

**Key sections:**
- Detailed prohibited content list
- Enforcement matrix (warnings → bans)
- Reporting process
- DMCA procedures

**Format:** Markdown (convert to HTML)

**Unique feature:** Violation severity table with clear penalties

---

### 4. App Store Description (4,000 characters)

**What it includes:**
- App name and subtitle suggestions
- 2 description versions (Concise + Detailed)
- Keyword suggestions (3 options)
- "What's New" templates
- Promotional text (170 char limit)
- App preview video script
- Screenshot captions and layout

**Key features:**
- AI disclosure prominent
- Credit system explained clearly
- Privacy highlights
- Feature lists
- Use case examples

**Format:** Markdown with plain text ready to copy-paste

---

### 5. App Review Notes (6,000+ words)

**What it includes:**
- Demo account info
- Quick start guide for reviewers
- Feature testing instructions
- Non-obvious features explained
- Privacy & security details
- Known limitations
- Compliance checklist
- Common questions anticipated

**Key sections:**
- Step-by-step testing guide
- DeviceCheck explanation
- Content moderation overview
- Backend accessibility confirmation
- Troubleshooting tips

**Format:** Markdown (paste into App Store Connect)

---

### 6. Support FAQ (4,500+ words)

**What it covers:**
- Getting started (8 Q&A)
- Video generation (7 Q&A)
- Credits & purchases (8 Q&A)
- Account & privacy (6 Q&A)
- Technical issues (5 Q&A)
- Content & safety (7 Q&A)
- Billing & refunds (6 Q&A)
- Contact support (4 Q&A)

**Total:** 51 Q&A pairs covering all common questions

**Format:** Markdown (convert to HTML or use as-is)

---

## ✅ What Makes These Documents Special

### 1. AI App-Specific
- Tailored for AI-generated content apps
- Addresses Apple's UGC requirements
- Includes AI disclosure language
- Covers deepfake and impersonation concerns

### 2. RendioAI-Specific
- Credit system fully documented
- DeviceCheck authentication explained
- 7-day retention policy covered
- FalAI integration disclosed

### 3. Compliance-Ready
- ✅ GDPR-compliant (for EU users)
- ✅ COPPA-aware (13+ age requirement)
- ✅ Apple HIG-aligned
- ✅ App Store Guidelines-compliant
- ✅ Privacy Manifest-ready

### 4. User-Friendly
- Plain language (not just legal jargon)
- TL;DR summaries included
- Examples and scenarios
- Clear formatting with emojis (where appropriate)

### 5. Comprehensive
- Over 30,000 words total
- 6 complete documents
- Implementation checklists
- Real-world examples

---

## 🚨 Critical Pre-Submission Requirements

Based on `AppStore-Compliance-NonEU.md`, these documents address:

| Requirement | Document | Status |
|-------------|----------|--------|
| Privacy Policy | PRIVACY_POLICY.md | ✅ Complete |
| Content Moderation | ACCEPTABLE_USE_POLICY.md | ✅ Complete |
| AI Disclosure | APP_STORE_DESCRIPTION.md | ✅ Complete |
| Terms of Service | TERMS_OF_SERVICE.md | ✅ Complete |
| Support Contact | SUPPORT_FAQ.md | ✅ Complete |
| Review Instructions | APP_REVIEW_NOTES.md | ✅ Complete |
| Age Rating Guidance | APP_REVIEW_NOTES.md | ✅ Complete |
| Data Deletion | PRIVACY_POLICY.md + TERMS | ✅ Complete |

**Remaining implementation tasks:**
- [ ] Add "Report" button in iOS app
- [ ] Implement account deletion in iOS app
- [ ] Create `content_reports` table in backend
- [ ] Set up email inboxes (support@, abuse@, etc.)
- [ ] Create Privacy Manifest (PrivacyInfo.xcprivacy)

---

## 📝 Customization Checklist

### Global Replacements Needed

Use find-and-replace in all documents:

| Placeholder | Replace With | Example |
|-------------|--------------|---------|
| `[INSERT DATE]` | Current date | 2025-11-16 |
| `[Your Company Name]` | Your company | Rendio Labs Inc. |
| `[Your Jurisdiction]` | Your location | California, USA |
| `support@rendio.ai` | Your support email | support@yourapp.com |
| `https://rendio.ai` | Your website | https://yourapp.com |
| `RendioAI` | Your app name | YourAppName |

### Company-Specific Info Needed

- [ ] Legal company name
- [ ] Mailing address (for Terms of Service)
- [ ] Registration number (if applicable)
- [ ] Email addresses:
  - support@
  - legal@
  - privacy@
  - abuse@
  - security@
  - appeals@
- [ ] Supabase data region (US, EU, etc.)

---

## 💰 Cost Breakdown

### DIY Approach (Free - $100)
- **Use these templates as-is:** $0
- **Domain + hosting:** $20-50/year
- **Email setup (Google Workspace):** $6/month
- **Total:** ~$100/year

### Professional Review ($500-2,000)
- **Lawyer review:** $500-1,500
- **Customization:** $200-500
- **Total:** $700-2,000 one-time

### Ongoing Costs
- **Domain + hosting:** $50/year
- **Email:** $72/year
- **Total:** ~$120/year

---

## ⏱️ Time Estimate

| Task | Time | Difficulty |
|------|------|------------|
| Review all documents | 2-3 hours | Easy |
| Customize placeholders | 1-2 hours | Easy |
| Publish to website | 1-2 hours | Medium |
| Add to App Store Connect | 30 min | Easy |
| Add links to iOS app | 1 hour | Easy |
| Legal review (optional) | 1-2 weeks | N/A |
| **Total (DIY):** | **6-9 hours** | Medium |
| **Total (with lawyer):** | **2-3 weeks** | Easy |

---

## 🎯 Next Steps

### Immediate (This Week)
1. [ ] Review all documents (2-3 hours)
2. [ ] Customize placeholders (1-2 hours)
3. [ ] Set up email addresses (30 min)
4. [ ] Publish to website (1-2 hours)

### Before Submission (Next Week)
1. [ ] Add to App Store Connect (30 min)
2. [ ] Add links to iOS app (1 hour)
3. [ ] Test all links (15 min)
4. [ ] Optional: Legal review (1-2 weeks)

### Post-Submission
1. [ ] Monitor support@ inbox
2. [ ] Respond to App Review questions
3. [ ] Update documents as needed

---

## 📞 Support

**Questions about these documents?**

Email: support@rendio.ai (or your email)

**Need legal advice?**

Consult a lawyer in your jurisdiction. These templates are NOT legal advice.

**Found an error?**

Please report it so we can fix it!

---

## 📄 License

These templates are provided for RendioAI and can be customized for your use.

**Disclaimer:** These are templates, not legal advice. Consult a lawyer before publishing.

---

## ✨ Summary

You now have **everything you need** for App Store compliance:

✅ **6 complete documents** (30,000+ words)
✅ **Implementation checklists** for each document
✅ **Customization guides** with find-and-replace instructions
✅ **Apple compliance** for AI UGC apps
✅ **User-friendly** language + TL;DR summaries
✅ **Ready to publish** (just customize and deploy)

**Estimated time to compliance:** 6-9 hours DIY, or 2-3 weeks with legal review

**Cost:** $0-2,000 depending on whether you hire a lawyer

**Next step:** Start with PRIVACY_POLICY.md and work through the checklist!

---

**Good luck with your App Store submission! 🚀**

**Questions?** Check SUPPORT_FAQ.md or email support@rendio.ai
