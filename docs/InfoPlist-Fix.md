# Fixing "Missing Info.plist / Invalid Bundle" Errors in iOS Projects

## Background

While trying to run the RendioAI iOS app, Xcode reported:

> `Build input file cannot be found ... Info.plist`
>
> or
>
> `The item at RendioAI.app is not a valid bundle. Failed to get the identifier for the app`.

Even though the project compiled, installation on device/simulator failed because the **generated app bundle was missing required metadata**.

## Root Cause

1. The `Info.plist` located under `RendioAI/RendioAI/` had been trimmed down to only the custom keys (Supabase URL, anon key, etc.).
2. As a result, mandatory keys such as `CFBundleIdentifier`, `CFBundleExecutable`, `CFBundlePackageType`, etc., were missing from the bundle that Xcode produces.
3. During install, iOS checks the bundle metadata, can’t find the identifier, and rejects the app with error 3000/3002.

> Note: A second `Info.plist` seated at the repository root wasn’t referenced by the target, so it had no effect.

## Fix Strategy

1. **Ensure the target’s `INFOPLIST_FILE` setting points to the correct file**.
   * In this project it should be `RendioAI/Info.plist` (relative to the `.xcodeproj`).
   * The value must be the same for Debug/Release (Project → Target → Build Settings → Packaging).

2. **Populate `Info.plist` with the full set of iOS bundle keys** plus the custom config entries.
   ```xml
   <key>CFBundleIdentifier</key>
   <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
   <key>CFBundleExecutable</key>
   <string>$(EXECUTABLE_NAME)</string>
   <key>CFBundlePackageType</key>
   <string>APPL</string>
   <key>CFBundleShortVersionString</key>
   <string>1.0</string>
   <key>CFBundleVersion</key>
   <string>1</string>
   <key>LSRequiresIPhoneOS</key>
   <true/>
   ...
   ```

3. **Keep dynamic values via `.xcconfig`** to avoid hardcoding secrets: e.g.
   * `SUPABASE_URL` → `$(SUPABASE_URL)`
   * `SUPABASE_ANON_KEY` → `$(SUPABASE_ANON_KEY)`

4. Delete any unused duplicate `.plist` files to avoid confusion.

5. **Clean build folder** (`Shift + Command + K`) and re-run.

## Lessons Learned

* Xcode will happily compile even if the bundle manifest is broken—installation time is where it fails.
* Maintaining a minimal `Info.plist` is *not enough*. You must include the standard iOS keys or iOS treats the bundle as invalid.
* When wiring configuration values through `.xcconfig`, you can still stay CI-friendly—just keep the standard keys in the `.plist` and inject the actual values via build settings.

## Applying to Other Projects

For each iOS app showing the same “invalid bundle / missing Info.plist” errors:
1. Check that the targeted `INFOPLIST_FILE` path in Build Settings points to the file you are editing.
2. Verify the `.plist` contains the required bundle keys.
3. Add your custom config keys at the bottom and reference them via `.xcconfig` or Environment.
4. Clean + rebuild.
5. If installing to physical device still fails, remove `DerivedData` (`~/Library/Developer/Xcode/DerivedData/ProjectName-*/`).

---
Created automatically on 2025-11-07.
