# Review, feature/firebase fcm, 2026-08-31

**Reviewed by**: gpt-5.6-sol (author on human or unknown)
**Scope**: 55 files, branch versus origin/dev
**Verdict**: Blocked

## Summary

This branch adds Firebase messaging, token registration, notification routing, live camera capture, and a large set of visual changes. The Dart suite is green, but a clean Android checkout does not build and the new camera path terminates the iOS app because its required privacy declaration is absent. The real backend push payload also does not match the payload used by the new routing tests, so several notification taps reach the wrong destination.

## Blockers

### 🔴 A clean Android checkout cannot build, `android/app/build.gradle.kts:3`

**Problem**: The Google Services Gradle plugin is applied for every Android build, while `.gitignore:59` ignores `google-services.json` and the repository does not provide that file or another configuration path. `flutter build apk --debug` fails at `:app:processDebugGoogleServices` with `File google-services.json is missing`.

**Why it matters**: CI and every fresh checkout fail before compiling the application. This prevents the branch from producing an Android artifact at all.

**Suggested fix**: You could provide the Firebase client configuration through a documented and automated build path. Committing the non secret Firebase client configuration is the usual option. If the team injects it in CI, you could also make that setup part of the repository build contract and verify a clean checkout build in CI.

### 🔴 Opening bill capture terminates the iOS app, `lib/features/bills/presentation/pages/bill_capture_page.dart:77`

**Problem**: The page now calls `availableCameras()` as soon as it opens, but `ios/Runner/Info.plist` has no `NSCameraUsageDescription`. The same file also lacks a photo library usage description even though the page opens the library.

**Why it matters**: iOS terminates an application that accesses a protected camera resource without its privacy usage string. PaySplit targets both iOS and Android, so a normal user path crashes one supported platform.

**Suggested fix**: You could add clear camera and photo library usage descriptions to the iOS target, then exercise first grant, denial, permanent denial, resume, capture, and gallery selection on a real iOS build.

## Major

### 🟠 Production push payloads do not contain the type used for routing, `lib/core/network/push_notification_handler.dart:171`

**Problem**: The click handler reads the notification kind only from `message.data['type']`, and the new tests all add that key. The current backend worker sends only the stored payload as FCM data. Several real producers store the kind in `Notification.Type` but omit it from the payload, including bulk finalize, settlement, and bill finalize jobs. For example, the bulk completion payload contains `batch_id` and `group_id`, but no `type`.

**Why it matters**: Real notification taps do not follow the tested branches. Bulk completion falls through to a plain group route and loses `openBatchId`, contrary to spec 0006, while settlement notifications can open the generic settlement surface instead of the correct tab.

**Suggested fix**: You could make the backend worker always copy `Notification.Type` into FCM data, then add contract tests using the exact backend payloads. Keeping safe fallback routing on the client for `batch_id`, `payment_id`, and other stable identifiers would also make delivery more resilient.

### 🟠 Firebase messaging is not configured for iOS, `lib/bootstrap.dart:22`

**Problem**: Bootstrap calls `Firebase.initializeApp()` without generated options, but the branch ignores `GoogleService-Info.plist` and supplies no iOS Firebase configuration. The iOS target also has no push notification entitlement or remote notification background mode.

**Why it matters**: Firebase initialization fails on iOS and the broad catch turns that into a warning, so the application continues without token registration or push delivery. The feature therefore works on only one of the two supported mobile platforms.

**Suggested fix**: You could add an automated iOS Firebase configuration path for every flavor, enable the Push Notifications capability and required background mode, and verify foreground, background, and terminated delivery on iOS.

### 🟠 A transient token sync failure disables push for the session, `lib/core/network/fcm_token_manager.dart:105`

**Problem**: A failed `PUT /users/me/fcm-token` is caught and reduced to `false`, with no retry, queued work, resume hook, or network reconnect hook. Initialization then completes normally. Unless Firebase refreshes the token or the app restarts, the same token is not sent again.

**Why it matters**: A brief network or backend outage during login can leave an otherwise healthy session without push notifications for days. The failure is invisible to the user and to callers.

**Suggested fix**: You could retain pending sync state and retry with bounded backoff when authentication and connectivity are available. App resume and successful token refresh are useful reconciliation points, and retries should remain scoped to the current authenticated session.

### 🟠 Security and lifecycle logic has no focused tests, `lib/core/network/fcm_token_manager.dart:35`

**Problem**: The branch adds branching logic for permission handling, authenticated token sync, refresh subscription replacement, logout deletion, foreground display, background taps, cold start taps, and camera lifecycle. The only added tests exercise the pure route resolver with hand written payloads. Existing camera widget tests do not initialize a camera or exercise permission and lifecycle transitions.

**Why it matters**: The test suite cannot catch token ownership mistakes, missed retries, duplicate subscriptions, cold start routing loss, logout leakage, or native permission regressions. These are the highest risk parts of this change.

**Suggested fix**: You could inject messaging, storage, transport, and navigation collaborators so the lifecycle can be tested without Firebase singletons. Focused tests should cover login and logout ownership, sync failure and retry, token refresh, foreground and cold start messages, malformed real backend payloads, and camera pause and resume behavior.

## Minor

### 🟡 Notification identifiers and tokens are written to logs, `lib/core/network/fcm_token_manager.dart:50`

**Problem**: The code logs complete FCM registration tokens and refreshed tokens. `push_notification_handler.dart:81` and `push_notification_handler.dart:96` also log complete data payloads, which can include group IDs, bill IDs, payment IDs, invite codes, and amounts.

**Why it matters**: These values can persist in device, CI, support, or crash collection logs and expose account linked metadata beyond the notification surface.

**Suggested fix**: You could remove token and payload values from logs. Stable event names, redacted suffixes, and bounded error categories provide useful diagnostics without recording private data.

### 🟡 Group bill cards now show creation time instead of bill date, `lib/features/groups/data/models/group_bill_mapper.dart:20`

**Problem**: The mapper changed from `billDate ?? createdAt` to `createdAt.toLocal()`. A receipt entered later than the actual purchase now displays the entry time instead of the business date supplied by the bill.

**Why it matters**: Users see the wrong date on the group bill card, especially for imported or backfilled receipts. It also discards a domain field that exists for this purpose.

**Suggested fix**: You could preserve `billDate` when present and normalize the chosen value to local time before formatting. A mapper test with different bill and creation dates would lock the behavior down.

### 🟡 Opening notifications starts duplicate initial requests, `lib/features/notifications/presentation/pages/notifications_page.dart:28`

**Problem**: `NotificationsNotifier` already calls `loadInitial()` in its constructor at line 73, and the page schedules `refresh()` on its first frame. When the provider is first created by this page, two list requests and two unread count requests run concurrently, with no ordering guard.

**Why it matters**: The page doubles backend work on first open and whichever response completes last can overwrite newer data with an older snapshot.

**Suggested fix**: You could make one layer own initial loading. If an entry refresh is required for an existing provider, you could await or deduplicate the in flight request and reject stale responses.

### 🟡 The unrelated visual rewrite conflicts with the governing spec, `lib/features/groups/presentation/pages/group_detail_page.dart:287`

**Problem**: Spec 0006 explicitly keeps the existing visual language, while this FCM branch changes colors, typography, spacing, radii, and dark theme handling across dozens of group, home, bill, invitation, and profile widgets. These surfaces have no matching visual or responsive test updates in this branch.

**Why it matters**: The broad scope makes notification review harder and can regress the specified 320, 375, 414, and 768 pixel layouts without a reviewable design decision or screenshot evidence.

**Suggested fix**: You could move the visual redesign into an approved design change and a separate focused branch. If it intentionally belongs here, the governing spec, screenshots, responsive checks, and important widget tests should change with it.

## Nits

* ⚪ `.gitignore:62`, `lib/app/app.dart:43`, `lib/bootstrap.dart:34`, and `test/app/notification_route_resolver_test.dart:225` add blank lines at end of file, so `git diff --check` fails.

## Strengths

* The route resolver remains defensive with malformed payloads, and its focused tests pass.
* Logout attempts server session revocation before local cleanup, then deletes the Firebase token and clears stored credentials. The notification read all request also now matches the backend `PATCH` contract.

## Test coverage

After ignored generated code was refreshed, all 214 Flutter tests passed. The focused notification route test also passed. `flutter analyze` reported only two existing unused imports outside this PR. The Android build failed because `google-services.json` is absent. Coverage is still missing for Firebase initialization, token registration and retry, logout ownership, real backend FCM payloads, foreground and terminated message handling, native camera permissions and lifecycle, and the broad responsive visual changes.
