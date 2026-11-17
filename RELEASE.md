# Where Did I Store It? — Release Guide

> **Important:** everything in sections 3–5 must be done later **on a Mac where you are signed in to your Apple ID** (Xcode → Settings → Accounts) with an active Apple Developer Program membership. Nothing has been signed, archived or uploaded yet.

Bundle ID: `ccms.WhereDidIStoreIt` · Version 1.0 (build 1) · iPhone only · iOS 17.0+ · Portrait

---

## 1. Before you submit — fill in these values

In `WhereDidIStoreIt/Views/SettingsView.swift`:

```swift
enum AppInfo {
    static let supportEmail = ""      // e.g. "you@example.com"
    static let privacyPolicyURL = ""  // URL where you host section 2 below
}
```

While these are empty, the **Help & Support** and **Privacy Policy** rows are hidden in Settings. Fill them in, rebuild, and then archive.

---

## 2. Privacy Policy (host this page publicly)

You can host it for free on GitHub Pages, Notion (public page) or Google Sites. Paste the URL into `AppInfo.privacyPolicyURL` **and** into App Store Connect → App Privacy → Privacy Policy URL.

```
Privacy Policy — Where Did I Store It?
Last updated: <DATE>

"Where Did I Store It?" ("the app") helps you remember where you stored your belongings.
This policy explains what happens to your information when you use it.

1. No data collection
The app does not collect, transmit, sell or share any personal information. It has no
accounts, no sign-in, no advertising, no analytics, no tracking and no third-party SDKs.
The app makes no network connections.

2. Data stored on your device
The items you save (names, categories, room / furniture / spot locations, dates,
descriptions, notes) and any photos you attach are stored only on your iPhone, inside
the app's private storage. They never leave your device through the app. If your device
backups (iCloud or computer) are enabled, this data may be included in those backups,
which are handled by Apple under your own backup settings.

3. Camera
If you choose "Take Photo", the app asks for camera access so you can photograph an item
and recognize it later. Photos are saved only inside the app on your device. You can
deny or revoke access at any time in Settings → Privacy & Security → Camera.

4. Photo library
If you choose "Choose from Photos", the app uses Apple's system photo picker. You select
a single photo, and only that photo is shared with the app. The app cannot see the rest
of your library and does not require full Photos access.

5. Deleting your data
You can delete any item (and its photo) from within the app, or erase everything at once
via Settings → Erase All Data. Deleting the app also removes all of its data.

6. Children
The app does not knowingly collect any information from anyone, including children.

7. Changes
If this policy changes, the updated version will be posted at this address with a new
"Last updated" date.

8. Contact
Questions? Email: <YOUR SUPPORT EMAIL>
```

---

## 3. App Store Connect answers

Create the app at **App Store Connect → Apps → + → New App**:

| Field | Value |
|---|---|
| Platform | iOS |
| Name | Where Did I Store It? |
| Primary language | English (U.S.) |
| Bundle ID | `ccms.WhereDidIStoreIt` (register it first under Certificates, Identifiers & Profiles if it isn't listed; Xcode automatic signing usually does this) |
| SKU | `wheredidistoreit-ios-001` (any unique string) |
| User access | Full Access |

### App Information
- **Subtitle (≤30 chars):** `Find your stuff, fast` (alternatives: `Remember where things are`)
- **Primary category:** Productivity · **Secondary:** Lifestyle (optional)
- **Content rights:** No third-party content.
- **Age rating questionnaire:** answer **None / No** to every item (no violence, no mature themes, no gambling, no user-generated content shared with others, no unrestricted web access, no messaging). Result: **4+**.

### App Privacy (Privacy Nutrition Label)
- "Do you or your third-party partners collect data from this app?" → **No, we do not collect data from this app.**
- Result shown on the store: **Data Not Collected**.
- Privacy Policy URL: the hosted page from section 2.

*(Data that stays on the device and is never sent off it does not count as "collected" under Apple's definitions.)*

### Version 1.0 page
- **Promotional text (≤170):** `Never lose track of your things again. Save where you stored anything — room, furniture and exact spot — and find it in seconds.`
- **Description:**

```
Where did I put my passport? The spare keys? That charger?

Where Did I Store It? is a simple, private place to remember where you stored your
belongings — so you can find them later without searching every drawer.

SAVE IT IN SECONDS
• Name the item and pick a category
• Choose the location step by step: Room → Furniture → Spot
• Add an optional photo, description and notes

FIND IT INSTANTLY
• Search by name, room, furniture, category or notes
• Filter by room or see what you added recently
• See the exact location at a glance

SEE YOUR HOME AT A GLANCE
• Recently stored items on the home screen
• A storage overview showing how your things are spread across rooms

PRIVATE BY DESIGN
• No account, no sign-in, no ads, no tracking
• Everything stays on your iPhone
• Works fully offline
```

- **Keywords (≤100 chars, comma-separated, no spaces needed):**
  `organizer,storage,find,items,belongings,inventory,home,where,lost,keys,declutter,remember,location`
- **Support URL (required):** a public web page where users can reach you. Simplest option: the same site that hosts the privacy policy, with a "Support" section containing your support email (e.g. `https://<you>.github.io/wheredidistoreit/support`). It must be a working http(s) URL; a bare `mailto:` is not accepted.
- **Marketing URL:** optional, leave empty.
- **Copyright:** `2026 <Your Name>`
- **App Review Information:** sign-in required → **No**. Notes: `Fully offline app. No account needed. Tap + to store an item; use Search or the Items tab to find it. Camera is optional (Take Photo); on devices without a camera, only "Choose from Photos" is shown.`
- **Export compliance:** already answered in the build (`ITSAppUsesNonExemptEncryption = NO`), so App Store Connect won't ask.

---

## 4. Screenshots (6.9" iPhone — required size 1320 × 2868 portrait)

Use the **iPhone 17 Pro Max** simulator (6.9"), run a **Release** or Debug build with realistic items you added yourself, and capture with **⌘S** in Simulator (or `xcrun simctl io booted screenshot file.png`). Upload 3–10; suggested set:

1. **Home** — greeting, Recently Stored cards, Storage Overview (with 6–10 items across several rooms, some with photos).
2. **Items** — the 2-column grid with photos and category badges, a room chip selected.
3. **Search** — typing "keys" with matching results and breadcrumbs.
4. **Item detail** — hero photo, breadcrumb pill, "Where It Is" card, notes.
5. **Add Item** — form with a photo, name, category and storage location filled in.
6. **Location picker** — Spot step with breadcrumb chips and "Confirm Location".
7. **Onboarding** — "Find It Instantly." page (optional).

Tip: in a Debug build, the 5 sample items have no photos — for nicer screenshots, add your own items with real photos first. Make sure the status bar looks clean (`xcrun simctl status_bar booted override --time 9:41 --batteryLevel 100 --cellularBars 4`).

---

## 5. Build, archive and upload (on your signed-in Mac)

1. Open `WhereDidIStoreIt.xcodeproj` in Xcode.
2. **Xcode → Settings → Accounts** → add your Apple ID (the one enrolled in the Apple Developer Program).
3. Select the **WhereDidIStoreIt** target → **Signing & Capabilities** → tick **Automatically manage signing** → choose your **Team**. (This is the only signing change needed; it was deliberately left untouched.)
4. Fill in `AppInfo.supportEmail` / `AppInfo.privacyPolicyURL` (section 1).
5. In the toolbar's run-destination menu choose **Any iOS Device (arm64)**.
6. **Product → Archive**. (Archive always uses the Release configuration, so the Debug sample data is not included.)
7. When the **Organizer** opens with the new archive: **Distribute App → App Store Connect → Distribute** (keep defaults: upload symbols, automatic signing). Wait for "Upload Successful".
8. In **App Store Connect → your app → TestFlight**: wait for the build to finish processing (5–30 min; you'll get an email).
9. **TestFlight → Internal Testing → +** create a group, add yourself/testers, add the build. Install via the TestFlight app on your iPhone and test: onboarding, add with camera + library photo, edit (location, replace photo, remove photo), delete, search, room filters, Erase All Data, force-quit & relaunch.
10. **App Store tab → iOS App 1.0**: fill the fields from section 3, upload screenshots (section 4), under **Build** click **+** and select the processed build.
11. **Add for Review → Submit to App Review.**

For later updates: bump **MARKETING_VERSION** (e.g. 1.0.1) and/or **CURRENT_PROJECT_VERSION** (build number must increase for every upload), then repeat steps 5–11.
