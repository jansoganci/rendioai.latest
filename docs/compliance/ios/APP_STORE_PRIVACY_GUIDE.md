# 📱 App Store Privacy Guide for RendioAI

**When submitting to App Store Connect, you'll need to answer privacy questions.**

This guide tells you **exactly what to select** based on your Privacy Manifest.

---

## 🔐 Privacy Nutrition Label Questions

When you submit your app, App Store Connect will ask you questions about data collection. Here's what to answer:

---

### **Question 1: Does your app collect data?**

**Answer:** ✅ **YES**

(You collect Device ID, User ID, Photos, Product Interaction, Purchase History)

---

### **Question 2: What data types do you collect?**

Select these **5 data types:**

---

#### **Data Type 1: Identifiers → Device ID**

**Do you collect Device IDs?** ✅ YES

**How is this data used?**
- ✅ App Functionality

**Is this data linked to the user?** ✅ YES

**Do you track this data?** ❌ NO

---

#### **Data Type 2: Identifiers → User ID**

**Do you collect User IDs?** ✅ YES

**How is this data used?**
- ✅ App Functionality

**Is this data linked to the user?** ✅ YES

**Do you track this data?** ❌ NO

---

#### **Data Type 3: Photos and Videos**

**Do you collect photos or videos?** ✅ YES

**How is this data used?**
- ✅ App Functionality

**Is this data linked to the user?** ❌ NO
(Photos are only stored temporarily for video generation)

**Do you track this data?** ❌ NO

---

#### **Data Type 4: Product Interaction**

**Do you collect Product Interaction data?** ✅ YES

**Examples:** Video generation history, which models used

**How is this data used?**
- ✅ App Functionality

**Is this data linked to the user?** ✅ YES

**Do you track this data?** ❌ NO

---

#### **Data Type 5: Purchases → Purchase History**

**Do you collect Purchase History?** ✅ YES

**Examples:** Credit purchases via In-App Purchase

**How is this data used?**
- ✅ App Functionality

**Is this data linked to the user?** ✅ YES

**Do you track this data?** ❌ NO

---

## 🚫 What You DON'T Collect

Make sure to select **NO** for these:

❌ Name
❌ Email Address (unless Apple Sign-In is used)
❌ Physical Address
❌ Phone Number
❌ Location
❌ Contacts
❌ Search History
❌ Browsing History
❌ Health & Fitness
❌ Financial Info
❌ Sensitive Info
❌ Diagnostics (unless you add crash reporting)
❌ Other Data

---

## 📊 Privacy Practices Summary

### **Does your app or third-party partners use data for tracking?**

**Answer:** ❌ **NO**

(Your app doesn't track users across other companies' apps/websites)

---

### **Do you or third-party partners collect data from this app?**

**Answer:** ✅ **YES**

(You collect the 5 data types listed above)

---

## 🔒 Data Protection

### **Do you use encryption for data in transit?**

**Answer:** ✅ **YES**

(All network requests use HTTPS via Supabase)

---

### **Can users request deletion of their data?**

**Answer:** ✅ **YES** (if you implement account deletion)
**Answer:** ❌ **NO** (if you don't have this feature yet)

**Note:** If you implement the delete account feature in ProfileView, select YES.

---

## 📝 Privacy Policy URL

You'll need to provide a **Privacy Policy URL**.

**Options:**

1. **Host on your website:** `https://yourwebsite.com/privacy`
2. **Use GitHub Pages:** Create a privacy policy and host it
3. **Use privacy policy generator:** Search "privacy policy generator" online

**Minimum content your privacy policy must include:**

- What data you collect (the 5 types above)
- How you use the data (app functionality)
- How long you store data
- How users can request deletion
- Your contact information

---

## 🎯 Quick Reference Checklist

When filling out App Store Connect:

**Data Collection:**
- ✅ Device ID → App Functionality → Linked → Not Tracked
- ✅ User ID → App Functionality → Linked → Not Tracked
- ✅ Photos/Videos → App Functionality → NOT Linked → Not Tracked
- ✅ Product Interaction → App Functionality → Linked → Not Tracked
- ✅ Purchase History → App Functionality → Linked → Not Tracked

**Tracking:**
- ❌ No tracking across other companies' apps

**Data Protection:**
- ✅ Encryption in transit (HTTPS)

**Privacy Policy:**
- ✅ Must provide URL

---

## ⚠️ Important Notes

### **1. Apple Sign-In (If you add it later)**

If you implement Apple Sign-In, you'll also need to declare:
- ✅ Email Address (only if user chooses to share)
- ✅ Name (only if user chooses to share)

Add these when you implement that feature.

---

### **2. Analytics (If you add them later)**

If you add Firebase, Mixpanel, or any analytics:
- ✅ Add "Usage Data" to data types
- ✅ Update Privacy Manifest to include analytics domains
- ✅ May need to declare tracking if analytics cross apps

---

### **3. Third-Party SDKs**

Your current dependencies and their privacy status:

| SDK | Has Privacy Manifest? | Notes |
|-----|----------------------|-------|
| **Supabase** | ✅ YES | Included automatically |
| **Kingfisher** | ✅ YES | Included automatically |
| **FalClient** | ❓ Unknown | May need manual declaration |
| **StableID** | ❓ Unknown | Already declared in your manifest |
| **StoreKit** | ✅ Apple SDK | No manifest needed |

**Good news:** Xcode automatically merges privacy manifests from dependencies!

---

## 🚀 Submission Day Checklist

Before you click "Submit for Review":

1. ✅ Privacy Manifest file exists (`PrivacyInfo.xcprivacy`) - **DONE**
2. ✅ Build includes Privacy Manifest - **VERIFIED**
3. ✅ Privacy Policy URL ready
4. ✅ App Store Connect privacy questions answered (use this guide)
5. ✅ Test submission on TestFlight first
6. ✅ Screenshots ready
7. ✅ App description written

---

## 📧 Privacy Policy Template (Quick Start)

If you need a simple privacy policy, here's a template:

```markdown
# Privacy Policy for RendioAI

Last updated: [DATE]

## What data we collect

- Device ID: To identify your device and save your credits
- User ID: To manage your account
- Photos: Temporarily to generate videos (not stored permanently)
- Video History: To show you your past generations
- Purchase History: To manage your credit purchases

## How we use this data

All data is used solely for app functionality. We do not:
- Track you across other apps
- Sell your data to third parties
- Use your data for advertising

## Data security

All data is transmitted using HTTPS encryption via Supabase.

## Data deletion

Contact us at [YOUR EMAIL] to request data deletion.

## Contact

For privacy questions, email: [YOUR EMAIL]
```

---

## ✅ You're Ready!

Your Privacy Manifest is complete and included in your app. When you submit to the App Store, just follow this guide!

**No more rejection due to missing privacy manifest!** 🎉
