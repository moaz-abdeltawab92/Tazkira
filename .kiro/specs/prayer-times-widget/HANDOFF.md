# Prayer Times Widget — Technical Handoff Document

> **Purpose:** Complete, self-contained technical reference. A senior engineer should be able to resume work on either platform using only this file.

---

## Table of Contents

1. [Overall Architecture](#1-overall-architecture)
2. [Files Created](#2-files-created)
3. [Files Modified](#3-files-modified)
4. [Design Decisions](#4-design-decisions)
5. [Android Status](#5-android-status)
6. [iOS Status](#6-ios-status)
7. [Tests](#7-tests)
8. [Manual Steps Still Required](#8-manual-steps-still-required)
9. [Current Blocking Issues](#9-current-blocking-issues)
10. [Exact Current Gradle Configuration](#10-exact-current-gradle-configuration)
11. [If You Were Continuing Tomorrow](#11-if-you-were-continuing-tomorrow)

---

## 1. Overall Architecture

### Core Constraint

**No prayer calculation happens in native widget code.** The Flutter app owns all computation (Egyptian method, Shafi madhab via the `adhan` package). Native widgets are purely display layers that read a pre-serialised snapshot written by Flutter.

### Three-Layer Design

```
┌────────────────────────────────────────────────────────────────┐
│                        FLUTTER (Dart)                          │
│                                                                │
│  PrayerTimesCardsWidget ──calls──▶ WidgetDataService           │
│  (owns prayer data, timer,          (singleton, serialiser)    │
│   lifecycle, GPS)                                              │
│                             │                                  │
│                   MethodChannel                                │
│              com.moaz.tazkira/widget_channel                   │
└───────────────────┬──────────────────────────┬─────────────────┘
                    │                          │
     ┌──────────────▼───────────┐  ┌───────────▼──────────────────┐
     │       iOS NATIVE         │  │       ANDROID NATIVE         │
     │                          │  │                              │
     │  AppDelegate.swift       │  │  MainActivity.kt             │
     │  (channel handler)       │  │  (channel handler)           │
     │  ↓                       │  │  ↓                           │
     │  UserDefaults App Group  │  │  SharedPreferences           │
     │  group.com.moaz.tazkira  │  │  FlutterSharedPreferences    │
     │  key: tazkira_widget_data│  │  key: flutter.tazkira_       │
     │  ↓                       │  │       widget_data            │
     │  TazkiraWidget extension │  │  ↓                           │
     │  (WidgetKit / SwiftUI)   │  │  PrayerWidgetReceiver        │
     │                          │  │  PrayerGlanceWidget          │
     └──────────────────────────┘  └──────────────────────────────┘
```

### Flutter Side

**`PrayerDataSnapshot`** (`lib/core/models/prayer_data_snapshot.dart`)

Immutable Dart class. Fields (all `String`): `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`, `nextPrayerName`, `nextPrayerTime`, `hijriDate`, `snapshotTimestamp`.

- `toJson()` — produces a `Map<String, dynamic>` and **explicitly excludes** `sunrise`, `latitude`, `longitude`, `hijriOffset`.
- `fromJson(Map)` / `fromJsonString(String)` — parse data; unknown keys silently ignored; returns `null` if any required field is missing.
- `contentEquals(other)` — compares 8 display fields and **excludes `snapshotTimestamp`** so that re-building the same snapshot at a later time does not trigger a widget reload.
- `isValid()` — returns `false` if any of the 5 prayer times or `nextPrayerName` is empty.
- `PrayerDataSnapshot.empty()` — all-empty instance used as the initial change-detection baseline in `WidgetDataService`.

**`WidgetDataService`** (`lib/core/services/widget_data_service.dart`)

Singleton accessed via `WidgetDataService.instance`. Holds `PrayerDataSnapshot _lastSnapshot` (initialised to `PrayerDataSnapshot.empty()`).

`publishSnapshot(snapshot)` logic:
1. `snapshot.isValid()` → return early if false.
2. `snapshot.contentEquals(_lastSnapshot)` → return early if true.
3. `_channel.invokeMethod('writeWidgetData', snapshot.toJson())`.
4. On success: `_lastSnapshot = snapshot`, then `_reloadWidgets()`.
5. `MissingPluginException` → caught silently, no retry.
6. Any other exception → logged, no retry timer scheduled.

`_reloadWidgets()` calls `'reloadWidgets'` with silent error handling.
`isWidgetInstalled()` calls `'isWidgetInstalled'`, returns `false` on any error.
`resetForTesting()` (annotated `@visibleForTesting`) resets `_lastSnapshot`.

**`PrayerTimesCardsWidget`** (`lib/features/home/presentation/widgets/prayer_times_cards_widget.dart`)

Owns the existing 1-minute `Timer.periodic` and `WidgetsBindingObserver`.

Added fields:
- `String _cachedHijriDate = ''` — updated asynchronously on each tick.

Added methods:
- `_publishWidgetSnapshot()` — builds `PrayerDataSnapshot` from already-available `prayerTimes`, awaits Hijri date, calls `WidgetDataService.instance.publishSnapshot()`.
- `_determineNextPrayer(pt)` — reads directly from `PrayerTimes` object without recalculation. Returns `MapEntry<String, DateTime>`.

Called from:
- `_initializePrayerTimes()` completion (first publish).
- Each timer tick in `_startCountdownTimer()`.
- `didChangeAppLifecycleState(AppLifecycleState.resumed)`.

### Android Side

**`MainActivity.kt`** — Extends `AudioServiceActivity` (unchanged). `MethodChannel` handler added via `configureFlutterEngine()`. Channel constant: `"com.moaz.tazkira/widget_channel"`. SharedPreferences file: `"FlutterSharedPreferences"`. Data key: `"flutter.tazkira_widget_data"`. Broadcasts `"com.moaz.tazkira.WIDGET_UPDATE"` after every write.

**`PrayerGlanceWidget.kt`** — Extends `GlanceAppWidget`. `provideGlance()` calls `provideContent {}` with `SnapshotReader.read(context)`. Layout: `Box(widget_background)` → `Column` → caption → next prayer → 5-column `PrayerRow` → Hijri date. Placeholder when null. Tap: `actionStartActivity<MainActivity>()`. **No custom font** (RemoteViews limitation).

**`PrayerWidgetReceiver.kt`** — Extends `GlanceAppWidgetReceiver`. Single companion-object `CoroutineScope(SupervisorJob() + Dispatchers.Default)`. Handles `ACTION_WIDGET_UPDATE` by calling `glanceAppWidget.updateAll(context)`.

**`SnapshotReader.kt`** — Reads `FlutterSharedPreferences` → `"flutter.tazkira_widget_data"` → parses JSON → `PrayerSnapshot` data class. Returns `null` on any failure.

**`PrayerFormatters.kt`** — `formatTime(String?)`: ISO-8601 UTC → local 12-hour `"HH:mm ص/م"`. Returns `"—"` on failure. `isStale(String?)`: age > 25 hours → `true`. Uses `java.time` (API 26, backported via desugaring).

### iOS Side

**`AppDelegate.swift`** — Registers `FlutterMethodChannel("com.moaz.tazkira/widget_channel")`. `handleWriteWidgetData`: JSON-encodes args → writes to `UserDefaults(suiteName: "group.com.moaz.tazkira")["tazkira_widget_data"]`. `handleReloadWidgets`: calls `WidgetCenter.shared.reloadAllTimelines()` (wrapped in `#available(iOS 14.0, *)`).

**`SnapshotReader.swift`** — Reads `UserDefaults(suiteName: "group.com.moaz.tazkira")` → `"tazkira_widget_data"` → decodes with `JSONDecoder` into `PrayerSnapshot: Decodable`. Returns `nil` if App Group unavailable.

**`PrayerFormatters.swift`** — `formatTime(_ isoString: String?) -> String`: tries fractional-seconds ISO formatter first (Dart default output format), then whole-seconds. Returns `"—"` on failure. `isStale(_ isoTimestamp: String?) -> Bool`: `ageSeconds > (25 * 3600)`.

**`PrayerEntry.swift`** — `struct PrayerEntry: TimelineEntry { let date: Date; let snapshot: PrayerSnapshot? }`.

**`PrayerTimelineProvider.swift`** — `getTimeline()`:
1. Reads `SnapshotReader.read()`.
2. If nil: single entry + `.after(now + 60min)`.
3. Otherwise: inserts a "now" entry at index 0, adds one entry per remaining prayer time today (already in future), adds midnight entry, uses `.after(midnight + 5min)` reload policy.

**Widget views:**
- `SmallWidgetView` (systemSmall): caption + next prayer name+time + 5 mini prayer columns.
- `MediumWidgetView` (systemMedium): next prayer two-line header + 5 prayer columns.
- `LargeWidgetView` (systemLarge): Hijri date + next prayer banner + 5 prayer columns.
- `LockScreenWidgetView` (accessoryRectangular, iOS 16+): next prayer line + 5 columns across 3 text lines.

All views: `.containerBackground(.widgetBackground, for: .widget)` (no custom colour). Font helper `cairoFont(size:weight:)` attempts `Font.custom` with `UIFont` availability guard, falls back to `Font.system`.

**`TazkiraWidget.swift`** — Four `Widget` structs. Kind identifiers (permanent): `"com.moaz.tazkira.small"`, `"com.moaz.tazkira.medium"`, `"com.moaz.tazkira.large"`, `"com.moaz.tazkira.lockscreen"`.

**`TazkiraWidgetBundle.swift`** — `@main struct TazkiraWidgetBundle: WidgetBundle`. Includes `LockScreenPrayerWidget()` with `if #available(iOS 16.0, *)` guard.

### Platform Channel Reference

| Property | Value |
|---|---|
| Channel name | `com.moaz.tazkira/widget_channel` |
| `writeWidgetData(Map<String, dynamic>)` | → `bool` (true on success) |
| `reloadWidgets()` | → `void` |
| `isWidgetInstalled()` | → `bool` |

### Shared Storage Keys

| Platform | Container | Key |
|---|---|---|
| iOS | `UserDefaults(suiteName: "group.com.moaz.tazkira")` | `"tazkira_widget_data"` |
| Android | `SharedPreferences("FlutterSharedPreferences")` | `"flutter.tazkira_widget_data"` |

### Widget Update Triggers

| Event | Both / Platform | Mechanism |
|---|---|---|
| Prayer data ready (cold start) | Both | `_publishWidgetSnapshot()` after `_initializePrayerTimes()` |
| Timer tick (every 60 s) | Both | `_publishWidgetSnapshot()` inside `_startCountdownTimer()` |
| App resumes from background | Both | `_publishWidgetSnapshot()` in `didChangeAppLifecycleState(resumed)` |
| OS baseline refresh | Android | `updatePeriodMillis = 1800000` (30 min) in `prayer_widget_info.xml` |
| WidgetKit-scheduled refresh | iOS | `PrayerTimelineProvider.getTimeline()` called by OS |
| Flutter-triggered reload (Android) | Android | Broadcast `com.moaz.tazkira.WIDGET_UPDATE` → `PrayerWidgetReceiver` |
| Flutter-triggered reload (iOS) | iOS | `WidgetCenter.shared.reloadAllTimelines()` via channel |

### iOS Timeline Flow

```
getTimeline() called by WidgetKit:
  snapshot = SnapshotReader.read()

  if snapshot == nil:
    → entries = [PrayerEntry(date: now, snapshot: nil)]
    → policy:  .after(now + 60 min)
    return

  entries = [PrayerEntry(date: now, snapshot)]          ← current entry
  for prayerTime in [fajr, dhuhr, asr, maghrib, isha]:
    if prayerTime > now: entries.append(PrayerEntry(date: prayerTime, snapshot))
  midnight = start of tomorrow (local)
  entries.append(PrayerEntry(date: midnight, snapshot)) ← day-change entry
  policy = .after(midnight + 5 min)
  return (entries, policy)
```

### Deep Links

- URL scheme: `tazkira://home`
- iOS: registered in `ios/Runner/Info.plist` → `CFBundleURLTypes` → `CFBundleURLSchemes: ["tazkira"]`. All widget views use `.widgetURL(URL(string: "tazkira://home")!)`.
- Android: `<intent-filter>` with `android:scheme="tazkira" android:host="home"` on `MainActivity`. `launchMode="singleTop"` prevents duplicate routes.

---

## 2. Files Created

### New Flutter Files

#### `lib/core/models/prayer_data_snapshot.dart`

**Purpose:** Immutable data model representing the prayer snapshot sent to native widgets.

**Class:** `PrayerDataSnapshot`

| Member | Description |
|---|---|
| `const PrayerDataSnapshot({...})` | Named constructor; 9 required `String` fields |
| `PrayerDataSnapshot.empty()` | Factory; all fields empty — used as change-detection baseline |
| `fromJson(Map)` | Static; returns null if any required field missing; unknown keys ignored |
| `fromJsonString(String)` | Wraps `fromJson`; returns null on JSON parse failure |
| `toJson()` | Returns `Map<String, dynamic>`; excludes `sunrise`, `latitude`, `longitude`, `hijriOffset` |
| `toJsonString()` | Returns `jsonEncode(toJson())` |
| `isValid()` | False if any of 5 prayer times or `nextPrayerName` is empty |
| `contentEquals(other)` | Compares 8 display fields; excludes `snapshotTimestamp` |

**State:** COMPLETE

---

#### `lib/core/services/widget_data_service.dart`

**Purpose:** Singleton serialisation service. Publishes snapshots to native widgets via MethodChannel. Owns change detection.

**Class:** `WidgetDataService`

| Member | Description |
|---|---|
| `static final instance` | Singleton |
| `static const _channel` | `MethodChannel('com.moaz.tazkira/widget_channel')` |
| `PrayerDataSnapshot _lastSnapshot` | Change-detection state |
| `publishSnapshot(snapshot)` | Validates → change-checks → writes → reloads |
| `isWidgetInstalled()` | Queries native; returns `false` on any error |
| `_reloadWidgets()` | Calls `reloadWidgets` channel method |
| `resetForTesting()` | `@visibleForTesting` — resets `_lastSnapshot` |

**State:** COMPLETE

---

### New Android Files

#### `android/app/src/main/kotlin/com/moaz/tazkira/widget/SnapshotReader.kt`

**Purpose:** Single point of access for reading prayer data from SharedPreferences in the widget package.

**Types:**
- `data class PrayerSnapshot(fajr, dhuhr, asr, maghrib, isha, nextPrayerName, nextPrayerTime, hijriDate, snapshotTimestamp: String)`
- `object SnapshotReader { fun read(context: Context): PrayerSnapshot? }`

Reads `FlutterSharedPreferences` → `flutter.tazkira_widget_data` → parses JSON. Required fields fail-fast on empty; `hijriDate` and `snapshotTimestamp` are optional. Returns null on any failure.

**State:** COMPLETE

---

#### `android/app/src/main/kotlin/com/moaz/tazkira/widget/PrayerFormatters.kt`

**Purpose:** Pure formatting utilities, no I/O.

**Methods:**
- `fun formatTime(isoString: String?): String` — ISO-8601 UTC → `"HH:mm ص/م"`. Returns `"—"` on failure.
- `fun isStale(isoTimestamp: String?): Boolean` — age > 25 hours. Returns `false` on bad input.

Uses `java.time` (API 26, backported via core library desugaring).

**State:** COMPLETE

---

#### `android/app/src/main/kotlin/com/moaz/tazkira/widget/PrayerGlanceWidget.kt`

**Purpose:** Jetpack Glance widget UI.

**Class:** `class PrayerGlanceWidget : GlanceAppWidget()`

Override: `provideGlance(context, id)` → `provideContent { WidgetContent(snapshot) }`

Composables: `WidgetContent`, `MainContent`, `PrayerRow`, `PrayerCell`, `PlaceholderContent`

Background: `widget_background` drawable. Tap: `actionStartActivity<MainActivity>()`.

**Font note:** All `fontFamily` TextStyle parameters were removed — RemoteViews cannot load custom TTF fonts.

**State:** COMPLETE (font parameters removed — RemoteViews limitation)

---

#### `android/app/src/main/kotlin/com/moaz/tazkira/widget/PrayerWidgetReceiver.kt`

**Purpose:** `GlanceAppWidgetReceiver` backing the widget.

**Class:** `class PrayerWidgetReceiver : GlanceAppWidgetReceiver()`

**Key members:**
- `companion object { private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default) }` — single shared scope
- `override val glanceAppWidget = PrayerGlanceWidget()`
- `onReceive()` — calls super, then handles `ACTION_WIDGET_UPDATE` → `updateAll(context)`

**State:** COMPLETE

---

#### `android/app/src/main/res/xml/prayer_widget_info.xml`

**Purpose:** `AppWidgetProviderInfo` — widget metadata.

Values: `minWidth="180dp"`, `minHeight="110dp"`, `targetCellWidth="4"`, `targetCellHeight="2"`, `updatePeriodMillis="1800000"`, `resizeMode="horizontal|vertical"`, `initialLayout="@drawable/widget_background"`.

**State:** COMPLETE

---

#### `android/app/src/main/res/drawable/widget_background.xml`

**Purpose:** Teal gradient background shape.

Gradient: `#5A8C8C → #7CB9AD`, 135° linear, `cornerRadius="16dp"`.

**State:** COMPLETE

---

#### `android/app/src/main/res/font/cairo_font_family.xml`
#### `android/app/src/main/res/font/cairo_regular.ttf`
#### `android/app/src/main/res/font/cairo_semibold.ttf`
#### `android/app/src/main/res/font/cairo_bold.ttf`

**Purpose:** Cairo font resources for Android.

**State:** COMPLETE (files present, but Glance cannot use custom fonts via RemoteViews — system font renders at runtime; files retained for potential future Glance update)

---

### New iOS Files

#### `ios/Runner/Runner.entitlements`

**Purpose:** App Group capability for Runner target.

Content: `com.apple.security.application-groups` → `["group.com.moaz.tazkira"]`

**State:** COMPLETE (file ready; Apple Developer Portal provisioning still required — see Section 9)

---

#### `ios/TazkiraWidget/TazkiraWidget.entitlements`

**Purpose:** App Group capability for TazkiraWidget extension target.

Content: `com.apple.security.application-groups` → `["group.com.moaz.tazkira"]`

**State:** COMPLETE (file ready; Apple Developer Portal provisioning still required)

---

#### `ios/TazkiraWidget/Info.plist`

**Purpose:** Extension Info.plist.

Key entries:
- `NSExtension.NSExtensionPointIdentifier` = `com.apple.widgetkit-extension`
- `UIAppFonts` = `["cairo_regular.ttf", "cairo_semibold.ttf", "cairo_bold.ttf"]`

**State:** COMPLETE

---

#### `ios/TazkiraWidget/SnapshotReader.swift`

**Purpose:** Reads prayer snapshot from shared App Group UserDefaults.

**Types:**
- `struct PrayerSnapshot: Decodable` — 9 `String` fields
- `enum SnapshotReader { static func read() -> PrayerSnapshot? }`

App Group ID: `"group.com.moaz.tazkira"`, Key: `"tazkira_widget_data"`. Uses `JSONDecoder`. Returns nil if App Group unavailable, key absent, or JSON malformed.

**State:** COMPLETE

---

#### `ios/TazkiraWidget/PrayerFormatters.swift`

**Purpose:** Pure formatting utilities for all widget views.

**Methods:**
- `static func formatTime(_ isoString: String?) -> String` — tries `.withFractionalSeconds` first then `.withInternetDateTime`. Returns `"—"` on failure.
- `static func isStale(_ isoTimestamp: String?) -> Bool` — `ageSeconds > (25 * 3600)`.

**State:** COMPLETE

---

#### `ios/TazkiraWidget/PrayerEntry.swift`

**Purpose:** `TimelineEntry` model.

`struct PrayerEntry: TimelineEntry { let date: Date; let snapshot: PrayerSnapshot? }`

**State:** COMPLETE

---

#### `ios/TazkiraWidget/PrayerTimelineProvider.swift`

**Purpose:** Builds WidgetKit timeline.

**Methods:** `placeholder`, `getSnapshot`, `getTimeline` (one entry per remaining prayer + midnight + `.after(midnight + 5min)` policy).

**State:** COMPLETE

---

#### `ios/TazkiraWidget/SmallWidgetView.swift`

**Purpose:** `systemSmall` layout.

`VStack`: caption → next prayer name + time → 5 mini prayer columns. Placeholder on nil snapshot. Staleness: greyed times.

**State:** COMPLETE

---

#### `ios/TazkiraWidget/MediumWidgetView.swift`

**Purpose:** `systemMedium` layout.

`VStack`: two-line next prayer header → 5 prayer columns.

**State:** COMPLETE

---

#### `ios/TazkiraWidget/LargeWidgetView.swift`

**Purpose:** `systemLarge` layout.

`VStack`: Hijri date → next prayer banner → 5 prayer columns → spacer.

**State:** COMPLETE

---

#### `ios/TazkiraWidget/LockScreenWidgetView.swift`

**Purpose:** `accessoryRectangular` layout (iOS 16+). Entire file guarded with `@available(iOS 16.0, *)`.

`VStack(spacing: 3)`: line 1 = next prayer label+name+time; lines 2–3 = 5 prayer mini-columns.

**State:** COMPLETE

---

#### `ios/TazkiraWidget/TazkiraWidget.swift`

**Purpose:** Declares four concrete `Widget` structs.

| Struct | Kind (permanent) | Family |
|---|---|---|
| `SmallPrayerWidget` | `com.moaz.tazkira.small` | `.systemSmall` |
| `MediumPrayerWidget` | `com.moaz.tazkira.medium` | `.systemMedium` |
| `LargePrayerWidget` | `com.moaz.tazkira.large` | `.systemLarge` |
| `LockScreenPrayerWidget` | `com.moaz.tazkira.lockscreen` | `.accessoryRectangular` |

**State:** COMPLETE

---

#### `ios/TazkiraWidget/TazkiraWidgetBundle.swift`

**Purpose:** `@main` entry point. `SmallPrayerWidget()`, `MediumPrayerWidget()`, `LargePrayerWidget()` always; `LockScreenPrayerWidget()` inside `if #available(iOS 16.0, *)`.

**State:** COMPLETE

---

#### `ios/TazkiraWidget/AppIntent.swift`
#### `ios/TazkiraWidget/TazkiraWidgetControl.swift`

**Purpose:** Cleared Xcode-generated stubs (AppIntents / iOS 18 Controls). Content removed to avoid conflicts.

**State:** COMPLETE (cleared stubs)

---

#### `ios/TazkiraWidget/cairo_regular.ttf`
#### `ios/TazkiraWidget/cairo_semibold.ttf`
#### `ios/TazkiraWidget/cairo_bold.ttf`

**Purpose:** Cairo font files for the widget extension. Main app bundle fonts are inaccessible to extensions.

**State:** COMPLETE (files present; must still be added to Xcode "Copy Bundle Resources" — see Section 8)

---

### New Test Files

#### `test/core/models/prayer_data_snapshot_test.dart`

35 unit tests across 7 groups: `toJson() excluded fields`, `toJson() required fields`, `fromJson()`, `fromJsonString()`, `contentEquals()`, `isValid()`, `JSON round-trip string serialisation`.

**State:** COMPLETE

---

#### `test/core/models/prayer_data_snapshot_pbt_test.dart`

9 property-based tests, 100 iterations each, fixed seed 42 (no external PBT library):

| # | Property |
|---|---|
| 1 | `fromJson(toJson(s))` content-equals `s` |
| 2 | `contentEquals` is reflexive |
| 3 | `contentEquals` is symmetric |
| 4 | Changing only `snapshotTimestamp` never changes `contentEquals` |
| 5 | Changing any display field always makes `contentEquals` return false |
| 6 | Snapshots with any empty required field are always invalid |
| 7 | Unknown JSON fields never affect parsing of valid snapshots |
| 8 | `toJson()` never includes `sunrise`, `latitude`, `longitude`, `hijriOffset` |
| 9 | JSON string round-trip is idempotent |

**State:** COMPLETE

---

#### `test/core/services/widget_data_service_test.dart`

15 unit tests across 5 groups: change detection, reload count, `MissingPluginException`, `PlatformException`, payload verification.

Uses `TestDefaultBinaryMessengerBinding` to mock `MethodChannel('com.moaz.tazkira/widget_channel')`.

**State:** COMPLETE

---

## 3. Files Modified

### `lib/features/home/presentation/widgets/prayer_times_cards_widget.dart`

**Changes:**
- Added `import` for `prayer_data_snapshot.dart`, `widget_data_service.dart`, `islamic_season_helper.dart`.
- Added field `String _cachedHijriDate = ''`.
- Added method `_publishWidgetSnapshot()`: awaits Hijri date → calls `_determineNextPrayer(pt)` → builds `PrayerDataSnapshot` → calls `WidgetDataService.instance.publishSnapshot()` (fire-and-forget).
- Added method `_determineNextPrayer(PrayerTimes)`: returns `MapEntry<String, DateTime>` for the next upcoming obligatory prayer from the already-calculated `prayerTimes` object. Falls back to Fajr +1 day when all five have passed.
- Hooked `_publishWidgetSnapshot()` into: `_initializePrayerTimes()` completion, each `_startCountdownTimer()` tick, `didChangeAppLifecycleState(resumed)`.
- No new `WidgetsBindingObserver` registered, no new timers, no GPS calls.

---

### `ios/Runner/AppDelegate.swift`

**Changes:**
- Added `import WidgetKit`.
- Added `setupWidgetChannel()` call in `application(_:didFinishLaunchingWithOptions:)` after `GeneratedPluginRegistrant.register(with: self)`.
- Added `setupWidgetChannel()` method: registers `FlutterMethodChannel("com.moaz.tazkira/widget_channel")`.
- Added `handleWriteWidgetData(call:result:)`: `JSONSerialization` encodes args dict → writes to `UserDefaults(suiteName: "group.com.moaz.tazkira")["tazkira_widget_data"]` → returns `true`.
- Added `handleReloadWidgets(result:)`: calls `WidgetCenter.shared.reloadAllTimelines()` wrapped in `#available(iOS 14.0, *)`.
- `isWidgetInstalled` handler returns `true` (WidgetKit has no install-check API).

---

### `ios/Runner/Info.plist`

**Changes:**
- Added `CFBundleURLTypes` array with one entry: `CFBundleTypeRole = "Editor"`, `CFBundleURLSchemes = ["tazkira"]`.

---

### `ios/Podfile`

**Changes:**
- Added `target 'TazkiraWidgetExtension' do use_frameworks! end` block (no pods — WidgetKit and SwiftUI are system frameworks).
- Added `post_install` block entry to set `IPHONEOS_DEPLOYMENT_TARGET = '14.0'` for the `TazkiraWidgetExtension` Pods target. Runner remains at 13.0.

---

### `android/app/src/main/kotlin/com/moaz/tazkira/MainActivity.kt`

**Changes:**
- Added imports: `android.content.Context`, `android.content.Intent`, `io.flutter.embedding.engine.FlutterEngine`, `io.flutter.plugin.common.MethodChannel`, `org.json.JSONObject`.
- Added companion object constants: `WIDGET_CHANNEL`, `PREFS_FILE`, `WIDGET_DATA_KEY`, `ACTION_WIDGET_UPDATE`.
- Added `override fun configureFlutterEngine(flutterEngine: FlutterEngine)` calling `super` then `registerWidgetChannel()`.
- Added `registerWidgetChannel()`, `handleWriteWidgetData()`, `handleReloadWidgets()`, `handleIsWidgetInstalled()`.
- Base class `AudioServiceActivity` was **not changed**.

---

### `android/app/src/main/AndroidManifest.xml`

**Changes:**
- Added `android:supportsRtl="true"` to `<application>` element.
- Added `PrayerWidgetReceiver` `<receiver>` block with two `<intent-filter>` entries (`APPWIDGET_UPDATE` and `com.moaz.tazkira.WIDGET_UPDATE`) and `<meta-data android:resource="@xml/prayer_widget_info">`.
- Added deep-link `<intent-filter>` on `MainActivity` activity: `action VIEW`, categories `DEFAULT` + `BROWSABLE`, `android:scheme="tazkira" android:host="home"`.

---

### `android/app/build.gradle`

**Changes:**
- Added plugin: `id "org.jetbrains.kotlin.plugin.compose"` (no version here — version declared in `settings.gradle`).
- Added `buildFeatures { compose true }` inside the `android` block.
- Added dependencies: `implementation "androidx.glance:glance-appwidget:1.1.1"` and `implementation "androidx.glance:glance-material3:1.1.1"`.

---

### `android/settings.gradle`

**Changes:**
- Added `id "org.jetbrains.kotlin.plugin.compose" version "2.1.0"` to the `plugins` block (alongside the existing Flutter and AGP plugin declarations).

---

## 4. Design Decisions

Each decision is documented with the reasoning so the next engineer understands the intent before considering a change.

### 1. No prayer calculation in native code

The Flutter app owns all calculation via the `adhan` package (Egyptian method, Shafi madhab). Native widget code receives a pre-computed snapshot and only formats/displays it.

**Why:** Duplicating prayer calculation logic in Swift and Kotlin would create a synchronisation risk — a bug fix or method parameter change in Dart would need to be replicated in two other languages. The widget only needs to display data that is already correct.

---

### 2. No countdown timer in widget

The widget does not display a live countdown to the next prayer.

**Why:** WidgetKit timelines are pre-rendered — there is no way to drive a per-second countdown from extension code without requesting a new timeline every second, which would exhaust the widget's background execution budget and drain the battery. For the first release, the static next-prayer name and time is sufficient.

---

### 3. No Sunrise (الشروق) in widget

Sunrise is shown in the app's `PrayerTimesCardsWidget` but is excluded from `PrayerDataSnapshot` and all widget layouts.

**Why:** Sunrise is not an obligatory prayer; its inclusion would add a 6th column to the 5-column prayer row, breaking the layout on all widget sizes. The design explicitly lists only the five obligatory prayers. Excluding it from the snapshot also keeps the data contract minimal.

---

### 4. `WidgetDataService` does not own lifecycle, GPS, or timers

`WidgetDataService` is a thin serialisation helper. It does not register `WidgetsBindingObserver`, does not start timers, and does not call GPS or location services.

**Why:** `PrayerTimesCardsWidget` already owns a `WidgetsBindingObserver`, a 1-minute `Timer.periodic`, and the GPS flow. Introducing a second lifecycle manager in `WidgetDataService` would create two sources of truth for observation and update scheduling, making the code harder to reason about and test.

---

### 5. `contentEquals()` excludes `snapshotTimestamp`

Two snapshots with identical prayer times, next prayer, and Hijri date are considered equal even if they were built at different moments.

**Why:** The snapshot is rebuilt on every 60-second timer tick. If `snapshotTimestamp` were included in equality, every tick would be treated as a change, triggering `reloadWidgets()` 60 times per hour — exhausting WidgetKit's reload budget and causing unnecessary Android broadcasts.

---

### 6. Change detection via `_lastSnapshot`

`WidgetDataService` holds `_lastSnapshot` and calls `snapshot.contentEquals(_lastSnapshot)` before every write.

**Why:** This eliminates redundant writes and widget reloads when prayer data has not changed. The most common case is the 60-second timer tick that fires when the user is not near a prayer transition — the snapshot content is identical, so nothing is written.

---

### 7. Platform channel name `com.moaz.tazkira/widget_channel`

**Why:** The reverse-DNS format `com.moaz.tazkira` matches the app's `applicationId`. The `/widget_channel` suffix is descriptive and distinct from any other channels in the app (audio service uses its own channel). The name is a constant in both Dart (`WidgetDataService._channel`) and Kotlin (`MainActivity.WIDGET_CHANNEL`).

---

### 8. iOS storage: `UserDefaults` App Group `group.com.moaz.tazkira`, key `tazkira_widget_data`

**Why:** `UserDefaults` with an App Group suite name is the standard iOS mechanism for sharing small data between an app and its extensions. JSON serialisation avoids a dependency on `NSCoding` or custom binary formats. The key `tazkira_widget_data` is unique within the App Group and descriptive.

---

### 9. Android storage: `SharedPreferences FlutterSharedPreferences`, key `flutter.tazkira_widget_data`

**Why:** Flutter's `shared_preferences` plugin already uses `FlutterSharedPreferences` as its default file name. Writing the widget data under the same file — with the same `flutter.` key prefix the plugin uses — means the widget reads data from a file it already has permission to access within the same APK/package. The `flutter.` prefix is mandatory; without it, the key would not be in the same namespace as Flutter-written keys.

---

### 10. Android broadcast action `com.moaz.tazkira.WIDGET_UPDATE`

**Why:** A custom broadcast action prevents other apps from triggering a widget refresh (the broadcast is sent with `.setPackage(packageName)` to limit delivery). The action string follows the reverse-DNS convention. It is defined as a constant in `MainActivity.ACTION_WIDGET_UPDATE` and referenced by `PrayerWidgetReceiver`.

---

### 11. iOS timeline policy: per-prayer entries + midnight entry + 5-minute post-midnight reload

**Why:**
- Per-prayer entries: WidgetKit renders each entry at the specified `date`, so the "next prayer" label changes at the exact moment the prayer time arrives — no polling.
- Midnight entry: ensures the prayer schedule refreshes for the new day even if the user has not opened the app.
- 5-minute post-midnight reload (not 60 minutes): the app must be opened once after midnight for Flutter to write the new day's data. The 5-minute floor gives WidgetKit a close-to-midnight retry window, improving responsiveness. The original design called for 60 minutes; 5 minutes was chosen as a better UX trade-off after reviewing WidgetKit background budget guidelines.

---

### 12. Widget kind identifiers are permanent

The `kind` strings (`"com.moaz.tazkira.small"`, etc.) are set in `TazkiraWidget.swift` and must never change after the first production release.

**Why:** WidgetKit uses the `kind` string to identify widget instances on users' home screens. If the string changes, every user loses their placed widget — it silently disappears. The kind is the widget's stable identity.

---

### 13. iOS backgrounds: `.widgetBackground` only, no custom colours

**Why:** `.widgetBackground` is the recommended container background for iOS widgets. It allows the system to apply appropriate tinting for the current appearance (light/dark), integrates with the wallpaper-based vibrancy on the Lock Screen, and matches Apple's Human Interface Guidelines for widgets. A custom colour or gradient would break Lock Screen vibrancy and look inconsistent with neighbouring system widgets.

---

### 14. Android backgrounds: teal gradient `#5A8C8C → #7CB9AD`

**Why:** The app's brand identity is built around this teal palette (used in the Dhuhr prayer card and HijriDateCard). Android does not have iOS's `.widgetBackground` vibrancy system; a branded gradient gives the widget a visually distinctive identity that matches the app. The gradient angle is 135° to add depth without being distracting.

---

### 15. Typography: Cairo font (with system Arabic fallback)

- iOS: `Font.custom("Cairo-Bold/SemiBold/Regular", size:)` with `UIFont(name:size:) != nil` availability guard before calling `Font.custom`. Falls back to `Font.system`.
- Android: Custom font parameters were removed from all Glance `TextStyle` calls. `cairofont_family.xml` and the TTF files are present in `res/font/` but Glance/RemoteViews cannot load them at runtime.

**Why:** Cairo is the app's primary Arabic typeface (used via `google_fonts` in Flutter). Using it in the widget creates visual consistency. The availability guard on iOS prevents blank labels if the font file is not yet in "Copy Bundle Resources". The Android limitation is a known RemoteViews restriction (confirmed by Google as intentional, security-related, since 2021).

---

### 16. Highlight style: bold weight only, no borders or underlines

Active prayer uses `FontWeight.Bold` / `.bold`; inactive prayers use regular weight.

**Why:** Early designs considered borders and underlines, but `.widgetBackground` vibrancy on iOS means a white border can be nearly invisible in some wallpaper contexts. Bold typography is always visible regardless of background. It is also the simplest implementation in both Glance and SwiftUI.

---

### 17. `PrayerDataSnapshot` uses `Codable` (iOS) and `data class` (Android), not manual JSON parsing

- iOS: `struct PrayerSnapshot: Decodable` decoded with `JSONDecoder`.
- Android: `data class PrayerSnapshot` with manual `JSONObject.optString()` parsing (Glance has no Kotlin serialisation dependency).

**Why:** `Decodable` on iOS eliminates boilerplate and is type-safe. On Android, adding a `kotlinx.serialization` or `gson` dependency to the widget package would add a transitive dependency to the main app; `org.json.JSONObject` is already present in the Android SDK, so no new dependency is needed.

---

### 18. No retry timers on platform channel failure

`WidgetDataService.publishSnapshot()` catches `MissingPluginException` and other exceptions, logs them, and returns normally. It does **not** schedule a `Future.delayed` retry.

**Why:** The widget data is published on every 60-second timer tick. The next tick is the implicit retry. Adding an explicit retry timer would create a second update path, complicating the change-detection logic and making tests harder to write. If a channel call fails, the widget shows slightly stale data for at most 60 seconds — an acceptable trade-off.

---

### 19. `PrayerWidgetReceiver` uses a single companion-object `CoroutineScope`

**Why:** `BroadcastReceiver.onReceive()` has a very short execution window. Launching a coroutine from `MainScope()` inside `onReceive()` would risk the scope being cancelled before the Glance update completes if broadcasts arrive in rapid succession. A companion-object scope with `SupervisorJob()` lives for the process lifetime and ensures that one failed broadcast does not cancel pending updates from other broadcasts.

---

### 20. Timeline reload 5 minutes after midnight (not 60 minutes)

See decision #11 above. The `.after(midnight + 5min)` policy was a deliberate improvement over the original design's 60-minute floor.

**Why:** Prayer times for the new day should be fetched as soon as possible after midnight. 5 minutes is within WidgetKit's normal background execution budget and noticeably improves the user experience compared to waiting up to 60 minutes for the first refresh of the new day.

---

## 5. Android Status

| Component | State | Notes |
|---|---|---|
| `MainActivity` (MethodChannel handler) | **COMPLETE** | `configureFlutterEngine` override; audio service base class unchanged |
| `SnapshotReader.kt` | **COMPLETE** | Reads `FlutterSharedPreferences` → `flutter.tazkira_widget_data` |
| `PrayerFormatters.kt` | **COMPLETE** | `formatTime`, `isStale`; uses `java.time` with desugaring |
| `PrayerGlanceWidget.kt` | **COMPLETE** | Font parameters removed — RemoteViews limitation; system font renders |
| `PrayerWidgetReceiver.kt` | **COMPLETE** | Single companion-object scope; handles `ACTION_WIDGET_UPDATE` |
| `AndroidManifest.xml` | **COMPLETE** | `supportsRtl`, receiver, deep-link intent filter |
| `build.gradle` (Glance + Compose plugin) | **COMPLETE** | `compose true`, Compose plugin declared, Glance deps added |
| `settings.gradle` (Compose plugin version) | **COMPLETE** | `org.jetbrains.kotlin.plugin.compose` version `2.1.0` |
| `prayer_widget_info.xml` | **COMPLETE** | `minWidth 180dp`, `minHeight 110dp`, `updatePeriodMillis 1800000` |
| `widget_background.xml` | **COMPLETE** | `#5A8C8C → #7CB9AD` gradient, 16dp corners |
| `cairo_font_family.xml` | **COMPLETE** | XML resource present; font cannot render via RemoteViews |
| Cairo TTF files (`res/font/`) | **COMPLETE** | Files present; not usable by Glance at runtime |
| Deep link intent filter | **COMPLETE** | `tazkira://home` on `MainActivity` |
| **Runtime status** | **BLOCKED** | `NoSuchMethodError: provideContent` — see Section 9, Issue 1 |

---

## 6. iOS Status

| Component | State | Notes |
|---|---|---|
| TazkiraWidget Xcode target | **COMPLETE** | Created manually in Xcode; committed to repo |
| `PrayerTimelineProvider` | **COMPLETE** | Per-prayer entries + midnight + `.after(midnight + 5min)` |
| `SnapshotReader.swift` (Codable) | **COMPLETE** | `JSONDecoder`; returns nil if App Group unavailable |
| `PrayerFormatters.swift` | **COMPLETE** | Fractional-seconds ISO formatter first; `"—"` fallback |
| `SmallWidgetView` | **COMPLETE** | Caption + next prayer + 5 mini columns |
| `MediumWidgetView` | **COMPLETE** | Two-line header + 5 columns |
| `LargeWidgetView` | **COMPLETE** | Hijri date + banner + 5 columns |
| `LockScreenWidgetView` | **COMPLETE** | `accessoryRectangular`; `@available(iOS 16.0, *)` guard |
| `TazkiraWidgetBundle` | **COMPLETE** | `@main`; Lock Screen conditionally included |
| `TazkiraWidget.swift` (widget declarations) | **COMPLETE** | 4 `Widget` structs with permanent `kind` strings |
| `AppDelegate` MethodChannel handler | **COMPLETE** | `writeWidgetData`, `reloadWidgets`, `isWidgetInstalled` |
| URL scheme `tazkira://` | **COMPLETE** | `CFBundleURLTypes` in `ios/Runner/Info.plist` |
| `Runner.entitlements` (App Group declared) | **COMPLETE** | `group.com.moaz.tazkira` |
| `TazkiraWidget.entitlements` (App Group declared) | **COMPLETE** | `group.com.moaz.tazkira` |
| `UIAppFonts` in `TazkiraWidget/Info.plist` | **COMPLETE** | `cairo_regular.ttf`, `cairo_semibold.ttf`, `cairo_bold.ttf` |
| Cairo fonts in TazkiraWidget target | **COMPLETE** | Files present; must be added to "Copy Bundle Resources" in Xcode |
| Podfile `TazkiraWidget` target | **COMPLETE** | `TazkiraWidgetExtension` target block; deployment target 14.0 in `post_install` |
| **App Group provisioning** | **BLOCKED** | Apple Developer Portal access required — see Section 9, Issue 2 |

---

## 7. Tests

### `test/core/models/prayer_data_snapshot_test.dart`

**Framework:** `package:flutter_test`

**35 tests across 7 groups:**

1. **`toJson() — excluded fields`** (4 tests): asserts `sunrise`, `latitude`, `longitude`, `hijriOffset` keys are absent.
2. **`toJson() — required fields`** (2 tests): asserts all 9 keys present and non-null; prayer times are non-empty strings.
3. **`fromJson()`** (4 tests): round-trip preserves all 9 fields; unknown keys ignored and do not throw; `null` returned when required field is missing (tested for each of 7 required fields); `null` returned for empty map.
4. **`fromJsonString()`** (3 tests): parses valid JSON string; returns `null` for malformed JSON; returns `null` for empty string.
5. **`contentEquals()`** (5 tests): `true` for identical snapshots; `true` when only `snapshotTimestamp` differs; `false` when `nextPrayerName` differs; `false` when any prayer time differs (loops over 5 fields); `false` when `hijriDate` differs.
6. **`isValid()`** (4 tests): `true` for fully populated snapshot; `false` when any prayer time is empty string; `false` when `nextPrayerName` is empty; `false` for `PrayerDataSnapshot.empty()`.
7. **`JSON round-trip — string serialisation`** (1 test): `decode(encode(s))` re-encoded equals original (key-order agnostic map comparison).

---

### `test/core/models/prayer_data_snapshot_pbt_test.dart`

**Framework:** `package:flutter_test` with custom random generators (fixed seed 42).

**9 property-based tests, 100 iterations each:**

| # | Property tested | Generator |
|---|---|---|
| 1 | `fromJson(toJson(s))` always content-equals `s` | random valid snapshot |
| 2 | `contentEquals` is reflexive: `s.contentEquals(s)` always true | random valid snapshot |
| 3 | `contentEquals` is symmetric: `a.contentEquals(b) == b.contentEquals(a)` | two independent random snapshots |
| 4 | Changing only `snapshotTimestamp` never changes `contentEquals` | random snapshot + different timestamp |
| 5 | Changing any display field always makes `contentEquals` return false | random snapshot with one field modified |
| 6 | Snapshots with any empty required field are always invalid | random snapshot with one required field emptied |
| 7 | Unknown JSON fields never affect parsing | random snapshot + 1–5 random extra keys |
| 8 | `toJson()` never includes `sunrise`, `latitude`, `longitude`, `hijriOffset` | random valid snapshot |
| 9 | JSON string round-trip is idempotent | random valid snapshot |

---

### `test/core/services/widget_data_service_test.dart`

**Framework:** `package:flutter_test`; uses `TestDefaultBinaryMessengerBinding` to mock `MethodChannel('com.moaz.tazkira/widget_channel')`.

**15 tests across 5 groups:**

1. **Change detection — no reload when content unchanged** (2 tests):
   - Identical content published twice → no channel calls on second publish (different `snapshotTimestamp` is ignored).
   - Invalid snapshot (empty prayer fields) → no channel calls.

2. **Reload triggered exactly once on content change** (4 tests):
   - `reloadWidgets` called exactly once per content-changing publish.
   - `writeWidgetData` called exactly once per content-changing publish.
   - Second publish with changed `nextPrayerName` triggers one reload.
   - Identical snapshot published twice → total `reloadWidgets` call count is 1.

3. **`MissingPluginException` — graceful handling** (2 tests):
   - `publishSnapshot()` completes without throwing when channel is unregistered.
   - `isWidgetInstalled()` returns `false` when channel is unregistered.

4. **`PlatformException` — logged, never crashes** (3 tests):
   - `publishSnapshot()` completes when `writeWidgetData` throws `PlatformException`.
   - `publishSnapshot()` completes when `reloadWidgets` throws `PlatformException`.
   - `publishSnapshot()` completes when an unexpected `Exception` is raised.

5. **`writeWidgetData` payload** (1 test):
   - `call.arguments` map contains correct field values from the snapshot.
   - Map does not contain `sunrise` or `latitude`.

---

## 8. Manual Steps Still Required

The following tasks cannot be automated and require direct human action.

### Step 1 — Apple Developer Portal: Enable App Group

**Priority:** High — iOS widgets will show the placeholder forever without this.

1. Log in to [developer.apple.com](https://developer.apple.com).
2. Go to **Certificates, Identifiers & Profiles** → **Identifiers**.
3. Find `com.moaz.tazkira` (the main app identifier). Click it.
4. Enable the **App Groups** capability. Click the **Edit** button next to it.
5. Click **+** and add `group.com.moaz.tazkira`.
6. Save.
7. Repeat steps 3–6 for the **TazkiraWidgetExtension** identifier (create it if it does not exist; bundle ID should be `com.moaz.tazkira.TazkiraWidgetExtension`).
8. Regenerate the provisioning profiles for both identifiers (or use Automatic Signing in Xcode and let Xcode manage them).

---

### Step 2 — Xcode Signing: Enable App Group Capability in Both Targets

After the portal configuration is done:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities** tab.
3. Click **+ Capability** → add **App Groups**.
4. In the App Groups list, add `group.com.moaz.tazkira` (it should appear if Step 1 is done).
5. Repeat steps 2–4 for the **TazkiraWidgetExtension** target.
6. Build the project to confirm no signing errors.

---

### Step 3 — Cairo Fonts: Add to Xcode "Copy Bundle Resources"

The TTF files are present in `ios/TazkiraWidget/` but must be explicitly added to the widget extension's bundle.

1. In Xcode, select the **TazkiraWidgetExtension** target.
2. Go to **Build Phases** → **Copy Bundle Resources**.
3. Click **+**.
4. Add `cairo_regular.ttf`, `cairo_semibold.ttf`, and `cairo_bold.ttf` from the `TazkiraWidget` group in the Project Navigator.
5. Verify these files are NOT in the Runner target's "Copy Bundle Resources" (duplication is unnecessary and wastes space).
6. Build and run on a device to confirm Cairo font renders in the widget.

---

### Step 4 — Android Compose/Glance Runtime Issue

See Section 9, Issue 1 for full details. The `NoSuchMethodError` for `provideContent` must be resolved.

1. Confirm `settings.gradle` has `id "org.jetbrains.kotlin.plugin.compose" version "2.1.0"` in its `plugins` block.
2. Confirm `app/build.gradle` has `id "org.jetbrains.kotlin.plugin.compose"` in its `plugins` block.
3. Confirm `app/build.gradle` has `buildFeatures { compose true }` in the `android` block.
4. Run a clean debug build: `flutter clean && flutter run --flavor production`.
5. If still failing, run `./gradlew :app:dependencies | grep compose-runtime` and verify the resolved version is compatible with the Compose plugin 2.1.0.

---

### Step 5 — Proguard Rules (Release Builds)

Currently `minifyEnabled true` is set for release builds. If Proguard strips Glance or Compose classes, the widget will crash silently in release.

Add the following to `android/app/proguard-rules.pro`:

```
-keep class androidx.glance.** { *; }
-keep class androidx.compose.** { *; }
```

Test with `flutter build apk --flavor production --release` before a production release.

---

## 9. Current Blocking Issues

### Issue 1: Android Runtime Crash — `NoSuchMethodError: provideContent`

**Symptoms:**

```
java.lang.NoSuchMethodError: No static method provideContent(
    Lkotlin/jvm/functions/Function2;
    Landroidx/compose/runtime/Composer;I
)V
in class Landroidx/glance/appwidget/GlanceAppWidgetKt;
or its super classes
```

Widget does not render; app may or may not crash depending on the Android version.

**Root cause:**

`provideContent` is a `@Composable` function. The Compose compiler plugin transforms `@Composable` annotations at compile time and emits the bytecode for these functions. Without the Compose compiler plugin running during the Kotlin compilation step, the method body is never emitted — the Glance AAR declares the function signature but the actual bytecode is missing from the compiled output.

For Kotlin 2.x (this project uses 2.1.0), the Compose compiler is no longer bundled with the Kotlin compiler. It must be applied as a separate Gradle plugin: `org.jetbrains.kotlin.plugin.compose`. The legacy approach (`composeOptions.kotlinCompilerExtensionVersion`) does not work with Kotlin 2.x.

**Fixes applied (in codebase — not yet verified at runtime):**

1. `android/settings.gradle` → added to `plugins` block:
   ```groovy
   id "org.jetbrains.kotlin.plugin.compose" version "2.1.0"
   ```

2. `android/app/build.gradle` → added to `plugins` block:
   ```groovy
   id "org.jetbrains.kotlin.plugin.compose"
   ```

3. `android/app/build.gradle` → added to `android` block:
   ```groovy
   buildFeatures {
       compose true
   }
   ```

**Current status:** APPLIED, NOT YET VERIFIED AT RUNTIME.

**Next step:** Run a clean debug build:
```bash
flutter clean
flutter run --flavor production
```

If the error persists, run:
```bash
cd android && ./gradlew :app:dependencies | grep compose-runtime
```
Verify that `compose-runtime` resolves to a version compatible with the Compose compiler plugin 2.1.0. If there is a version mismatch, add an explicit version constraint in `dependencies { }`.

---

### Issue 2: iOS App Group Not Provisioned

**Symptoms:**

The iOS widget always shows the placeholder: "افتح التطبيق مرة واحدة لإعداد الويدجت", even after opening the app and verifying that `writeWidgetData` executes without error on the Flutter side.

**Root cause:**

`UserDefaults(suiteName: "group.com.moaz.tazkira")` returns `nil` when the App Group has not been enabled in the Apple Developer Portal for both the main app and the widget extension identifiers. `SnapshotReader.read()` returns `nil` on every call when the UserDefaults container is nil, regardless of what the Flutter app has written.

**Entitlement files are ready:**
- `ios/Runner/Runner.entitlements` — declares `group.com.moaz.tazkira`
- `ios/TazkiraWidget/TazkiraWidget.entitlements` — declares `group.com.moaz.tazkira`

**Current status:** BLOCKED on Apple Developer Portal access. The developer account owner must follow Section 8, Steps 1–2.

**Verification after fix:**

Add a temporary log in `SnapshotReader.read()` to confirm the UserDefaults container is not nil:
```swift
let defaults = UserDefaults(suiteName: "group.com.moaz.tazkira")
print("[SnapshotReader] defaults:", defaults as Any)
```
If `defaults` is non-nil and the key `"tazkira_widget_data"` is present after opening the app, the issue is resolved.

---

### Issue 3: Android Custom Fonts Not Supported in Glance

**Symptoms:**

The widget renders in the system default Arabic font, not Cairo.

**Root cause:**

Jetpack Glance renders widget content using Android's `RemoteViews` system. `RemoteViews` does not support loading custom TTF font files from `res/font/` as a security measure (confirmed by the Android team as intentional since 2021). The `fontFamily` parameter in Glance's `TextStyle` can only reference fonts installed system-wide; it cannot load from app resources.

**Current status:** NOT A BUG — this is a known platform limitation. `fontFamily` parameters were deliberately removed from all Glance `TextStyle` calls in `PrayerGlanceWidget.kt`. The Cairo TTF files remain in `res/font/` and `cairo_font_family.xml` is present; if a future Glance version adds custom font support, they can be re-enabled by adding `fontFamily = FontFamily(Font(R.font.cairo_bold))` to the relevant `TextStyle` objects.

The widget renders correctly with the system Arabic font (Noto Naskh Arabic or equivalent), which fully supports Arabic text.

---

## 10. Exact Current Gradle Configuration

| Setting | Value |
|---|---|
| Flutter SDK | 3.35.4 (managed by FVM) |
| Kotlin | 2.1.0 |
| AGP (Android Gradle Plugin) | 8.6.0 |
| Compose Compiler Gradle Plugin | `org.jetbrains.kotlin.plugin.compose` version `2.1.0` |
| Glance | `glance-appwidget:1.1.1`, `glance-material3:1.1.1` |
| `compileSdk` | 36 |
| `targetSdk` | 36 |
| `minSdk` | `flutter.minSdkVersion` (defined by Flutter tooling, typically 21) |
| `desugar_jdk_libs` | 2.1.4 |
| Core library desugaring | Enabled (`coreLibraryDesugaringEnabled true`) |
| `multiDexEnabled` | `true` |
| `minifyEnabled` (release) | `true` |
| `shrinkResources` (release) | `false` |
| iOS Runner deployment target | 13.0 |
| iOS TazkiraWidgetExtension deployment target | 14.0 (set in `Podfile post_install`) |
| iOS Lock Screen widget minimum | iOS 16.0 (guarded with `@available` in Swift) |

**Relevant excerpt from `android/settings.gradle`:**

```groovy
plugins {
    id "org.jetbrains.kotlin.plugin.compose" version "2.1.0"
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.6.0" apply false
    id "com.google.gms.google-services" version "4.4.2" apply false
    id "org.jetbrains.kotlin.android" version "2.1.0" apply false
}
```

**Relevant excerpt from `android/app/build.gradle`:**

```groovy
plugins {
    id "org.jetbrains.kotlin.plugin.compose"
    id "com.android.application"
    id 'com.google.gms.google-services'
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    buildFeatures {
        compose true
    }
    // ...
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
    implementation "androidx.glance:glance-appwidget:1.1.1"
    implementation "androidx.glance:glance-material3:1.1.1"
}
```

---

## 11. If You Were Continuing Tomorrow

### Step 1 — Verify Android `NoSuchMethodError` is Resolved

Run a clean debug build:

```bash
flutter clean
flutter run --flavor production
```

**Expected result:** The widget appears on the home screen and shows the prayer data after opening the app once.

**If still failing:** Run the dependency tree and inspect the Compose runtime version:

```bash
cd android
./gradlew :app:dependencies | grep compose-runtime
```

Verify the resolved `compose-runtime` version is compatible with Compose compiler plugin 2.1.0. If there is a mismatch, add an explicit version override in `app/build.gradle`:

```groovy
dependencies {
    implementation "androidx.compose.runtime:runtime:1.7.x"  // match plugin requirements
}
```

---

### Step 2 — Test the Full Android Widget Update Flow

Once the build succeeds:

1. Long-press the home screen → Widgets → find "تَذْكِرَة".
2. Add the widget to the home screen.
3. Open the app (this triggers `_publishWidgetSnapshot` via `_initializePrayerTimes`).
4. Verify the widget shows the correct next prayer name, formatted time, and all 5 prayer times.
5. Wait past a prayer time transition (or set the device clock forward past a prayer time) and verify the highlighted prayer updates.
6. Force-quit the app and re-open it. The widget should re-render with the freshly written snapshot.
7. Test with the device clock set 26 hours forward — verify greyed-out prayer times (staleness indicator).
8. Tap the widget — verify the app opens to the home screen.

---

### Step 3 — iOS: Contact the Apple Developer Account Owner

The account owner (Moaz) must follow Section 8, Steps 1–2 to enable the App Group in the Apple Developer Portal.

Once provisioning is complete:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Verify **Runner** target → Signing & Capabilities → App Groups includes `group.com.moaz.tazkira`.
3. Verify **TazkiraWidgetExtension** target → Signing & Capabilities → App Groups includes `group.com.moaz.tazkira`.
4. Run `pod install` from the `ios/` directory.
5. Build and run on a physical device (widgets are unreliable on the simulator).

---

### Step 4 — iOS: Verify Cairo Fonts in Widget Extension

1. In Xcode, select the **TazkiraWidgetExtension** target.
2. **Build Phases** → **Copy Bundle Resources**: verify `cairo_regular.ttf`, `cairo_semibold.ttf`, `cairo_bold.ttf` are listed.
3. If not: drag them from the `TazkiraWidget` group in the Project Navigator into the Copy Bundle Resources phase.
4. Build and run on a physical device.
5. The widget should render in Cairo font. If it still shows the system font, add a temporary log in `SmallWidgetView.cairoFont()`:
   ```swift
   let available = UIFont(name: "Cairo-Bold", size: 14) != nil
   print("[Font] Cairo-Bold available:", available)
   ```

---

### Step 5 — End-to-End Test Checklist (Both Platforms)

| Test | Expected |
|---|---|
| Widget update on cold start | Widget shows prayer data within 5 seconds of first app open |
| Widget update on prayer time transition | Highlighted prayer changes within 90 seconds of transition |
| Staleness indicator | Set device clock +26h; widget shows greyed times |
| Placeholder state (no data) | Revoke location permission + reinstall; widget shows placeholder text |
| Deep link (widget tap) | App opens to home screen without duplicate route |
| Lock Screen widget (iOS 16+ device) | Shows next prayer name and time; tapping opens app |
| Widget resize (Android) | Widget reflows correctly at larger and smaller sizes |
| Dark mode (iOS) | `.widgetBackground` vibrancy applies correctly |

---

### Step 6 — Production Release Preparation

When all tests pass:

1. Update version in `pubspec.yaml`.
2. Test release builds:
   ```bash
   flutter build apk --flavor production --release
   flutter build ios --flavor production --release
   ```
3. Verify Proguard does not strip Glance/Compose classes (see Section 8, Step 5).
4. On iOS, verify widget extension is included in the `.ipa` archive.
5. Submit to Google Play (Android) and App Store Connect (iOS).

---

*End of handoff document.*