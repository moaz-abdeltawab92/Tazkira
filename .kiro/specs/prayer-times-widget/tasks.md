# Implementation Tasks — Prayer Times Widget

## Phase 1: Flutter Data Layer

- [ ] 1. Create `PrayerDataSnapshot` model
  - Create `lib/core/models/prayer_data_snapshot.dart`
  - Fields: `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`, `nextPrayerName`, `nextPrayerTime`, `hijriDate`, `snapshotTimestamp` (all `String`)
  - Implement `toJson()` — must NOT include `sunrise`, `latitude`, `longitude`
  - Implement `fromJson(Map<String, dynamic>)` — unknown fields are silently ignored
  - Implement `contentEquals(PrayerDataSnapshot other)` — compares all 8 content fields excluding `snapshotTimestamp`
  - Implement `isValid()` — returns false if any of the five prayer time fields or `nextPrayerName` is null/empty
  - _Requirements: 1.8, 13.1–13.4_

- [ ] 2. Create `WidgetDataService`
  - **Architecture note**: Search confirmed no equivalent service exists. `PrayerTimesCardsWidget` already owns the `WidgetsBindingObserver` + `Timer.periodic` lifecycle — `WidgetDataService` is a thin serialisation-only helper called from that widget. It does NOT manage its own lifecycle, timers, or location.
  - Create `lib/core/services/widget_data_service.dart`
  - Singleton class (private constructor + static instance)
  - `static const _channel = MethodChannel('com.moaz.tazkira/widget_channel')`
  - Field `PrayerDataSnapshot? _lastSnapshot` for change detection
  - `Future<void> publishSnapshot(PrayerDataSnapshot snapshot)`:
    - Calls `snapshot.isValid()` — if false, returns without writing
    - Calls `_hasChanged(snapshot)` — if false (data unchanged), returns without writing or reloading
    - Calls `_channel.invokeMethod('writeWidgetData', snapshot.toJson())`
    - On success: updates `_lastSnapshot`, calls `_reloadWidgets()`
    - Catches `MissingPluginException` — logs warning, returns silently (no retry)
    - Catches other `PlatformException` or `Exception` — logs error, returns silently; the next natural snapshot publication (next timer tick or app resume) will retry automatically
    - **No artificial retry timers** — do not schedule any `Future.delayed` retry
  - `Future<void> _reloadWidgets()`: calls `_channel.invokeMethod('reloadWidgets')`; catches all errors silently with a log
  - `bool _hasChanged(PrayerDataSnapshot snapshot)`: returns `!snapshot.contentEquals(_lastSnapshot ?? PrayerDataSnapshot.empty())`
  - `Future<bool> isWidgetInstalled()`: calls `_channel.invokeMethod('isWidgetInstalled')`, returns false on any error
  - _Requirements: 2.1–2.5, 16.1–16.7_

- [ ] 3. Integrate `WidgetDataService` into `PrayerTimesCardsWidget`
  - Modify `lib/features/home/presentation/widgets/prayer_times_cards_widget.dart`
  - In `_updateCountdown()` (already called every minute by existing `Timer.periodic`): after updating `_countdownText` and before/after `setState`, build a `PrayerDataSnapshot` from the **already-available** `prayerTimes` object (which holds all 5 prayer DateTimes) and the current `nextPrayerNameTemp` — **no new calculation, no new GPS call**
  - Read hijri date via `IslamicSeasonHelper.getAdjustedHijriDate()` (already used by `HijriDateCard`): call asynchronously in a `unawaited` pattern — store result in a cached field `String? _cachedHijriDate`, update it on each timer tick without blocking UI
  - Pass the snapshot to `WidgetDataService.instance.publishSnapshot(snapshot)` — fire-and-forget with `unawaited()`
  - In `didChangeAppLifecycleState` (already present in this widget): on `AppLifecycleState.resumed`, if `prayerTimes != null`, call `_updateCountdown()` which naturally triggers `publishSnapshot` — no additional code needed
  - Do NOT register any new `WidgetsBindingObserver`, do NOT add new timers, do NOT add GPS/location logic
  - **The existing timer and observer in this widget are the only update triggers**
  - _Requirements: 1.2, 1.4, 1.5_

## Phase 2: iOS — Platform Channel Handler

- [ ] 4. Add `MethodChannel` handler in `AppDelegate.swift`
  - Modify `ios/Runner/AppDelegate.swift`
  - After `GeneratedPluginRegistrant.register(with: self)`, set up `FlutterMethodChannel` with name `com.moaz.tazkira/widget_channel`
  - Handle `writeWidgetData(data)`:
    - Encode the `data` dictionary as a JSON string
    - Write to `UserDefaults(suiteName: "group.com.moaz.tazkira")` under key `"tazkira_widget_data"`
    - Return `true` on success, `false` on any error
  - Handle `reloadWidgets()`:
    - Import `WidgetKit`
    - Call `WidgetCenter.shared.reloadAllTimelines()` (wrapped in `@available(iOS 14.0, *)`)
    - Return `nil`
  - Handle `isWidgetInstalled()`: return `true` (WidgetKit has no install-check API)
  - All unrecognised method names: call `result(FlutterMethodNotImplemented)`
  - _Requirements: 2.1, 2.3, 16.3, 16.5_

## Phase 3: Android — Platform Channel Handler

- [ ] 5. Add `MethodChannel` handler in `MainActivity.kt`
  - Modify `android/app/src/main/kotlin/com/moaz/tazkira/MainActivity.kt`
  - Keep `AudioServiceActivity` as base class — do NOT change it
  - Override `configureFlutterEngine(flutterEngine: FlutterEngine)`; call `super.configureFlutterEngine(flutterEngine)`
  - Set up `MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.moaz.tazkira/widget_channel")`
  - Handle `writeWidgetData(data)`:
    - Receive `data` as `Map<String, Any>`
    - Serialize to JSON string using `org.json.JSONObject`
    - Write to `getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)` under key `"flutter.tazkira_widget_data"`
    - Broadcast `com.moaz.tazkira.WIDGET_UPDATE` intent
    - Return `true`
  - Handle `reloadWidgets()`: broadcast `com.moaz.tazkira.WIDGET_UPDATE`; return `null`
  - Handle `isWidgetInstalled()`: query `AppWidgetManager.getInstance(this)` for widget IDs of `PrayerWidgetReceiver`; return `true` if any active IDs exist
  - _Requirements: 2.2, 2.3, 16.4, 16.6_

## Phase 4: iOS — Widget Extension Setup

- [ ] 6. Create iOS Widget Extension setup and shared files
  - Create directory `ios/TazkiraWidget/`
  - Create `ios/TazkiraWidget/Info.plist` with `NSExtension` dictionary: `NSExtensionPointIdentifier = com.apple.widgetkit-extension`, `NSExtensionPrincipalClass = $(PRODUCT_MODULE_NAME).TazkiraWidgetBundle`
  - Create `ios/TazkiraWidget/TazkiraWidget.entitlements` with `com.apple.security.application-groups` array containing `group.com.moaz.tazkira`
  - Create or update `ios/Runner/Runner.entitlements` to include `com.apple.security.application-groups` → `group.com.moaz.tazkira`
  - Update `ios/Runner/Info.plist`: add `CFBundleURLTypes` entry with `CFBundleURLSchemes` = `["tazkira"]`
  - Update `ios/Podfile`:
    - Keep the Runner target at `platform :ios, '13.0'` (existing minimum — do NOT raise it)
    - Add a separate target block for `TazkiraWidget` with `platform :ios, '14.0'` (Home Screen widgets require iOS 14+)
    - The Lock Screen widget (`accessoryRectangular`) will be guarded with `@available(iOS 16.0, *)` in Swift — no Podfile change needed for that
  - Note for developer: Add `TazkiraWidget` target in Xcode manually (link `WidgetKit.framework` + `SwiftUI.framework`, set deployment target **iOS 14.0**, add App Group entitlement `group.com.moaz.tazkira`)
  - _Requirements: 8.1–8.5_

- [ ] 7. Create `SnapshotReader.swift` and `PrayerFormatters.swift`
  - Create `ios/TazkiraWidget/SnapshotReader.swift`:
    - `struct PrayerSnapshot` with fields: `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`, `nextPrayerName`, `nextPrayerTime`, `hijriDate`, `snapshotTimestamp` (all `String`)
    - `static func read() -> PrayerSnapshot?`: reads JSON string from `UserDefaults(suiteName: "group.com.moaz.tazkira")?["tazkira_widget_data"]`, decodes with `JSONDecoder`
    - Returns `nil` if key absent, JSON malformed, or any required field missing
  - Create `ios/TazkiraWidget/PrayerFormatters.swift`:
    - `static func formatTime(_ isoString: String) -> String`: parse ISO-8601 UTC → local `Date` → `"HH:mm ص/م"` format; return `"—"` on any parse failure
    - `static func isStale(_ isoTimestamp: String) -> Bool`: returns `true` if age > 25 hours (strictly greater)
  - _Requirements: 13.2, 13.5, 7.4_

- [ ] 8. Create `PrayerEntry.swift` and `PrayerTimelineProvider.swift`
  - Create `ios/TazkiraWidget/PrayerEntry.swift`:
    - `struct PrayerEntry: TimelineEntry` with `date: Date` and `snapshot: PrayerSnapshot?`
  - Create `ios/TazkiraWidget/PrayerTimelineProvider.swift`:
    - Implements `TimelineProvider`
    - `placeholder(in:)`: returns `PrayerEntry(date: Date(), snapshot: nil)`
    - `getSnapshot(in:completion:)`: reads snapshot, returns single entry
    - `getTimeline(in:completion:)`:
      - Reads snapshot from `SnapshotReader.read()`
      - Builds one `PrayerEntry` per remaining prayer transition for today (at each prayer's scheduled time), plus one entry at midnight
      - Uses `.atEnd` reload policy with `nextReloadDate` = `Date().addingTimeInterval(3600)` (60 minutes)
      - If snapshot is nil, returns single entry with `.after(Date().addingTimeInterval(3600))`
  - _Requirements: 7.1–7.3_

## Phase 5: iOS — Widget Views

- [ ] 9. Create `SmallWidgetView.swift`
  - Create `ios/TazkiraWidget/SmallWidgetView.swift`
  - Layout (VStack, centred):
    - Image: app icon (`Image("AppIcon")`) or SF Symbol `mosque` as fallback
    - Text: `"الصلاة القادمة"` — caption style, secondary color
    - Text: `snapshot.nextPrayerName` — headline bold, primary color
    - Text: `PrayerFormatters.formatTime(snapshot.nextPrayerTime)` — subheadline
  - If snapshot is nil: show `"افتح التطبيق لتحديث البيانات"` centred
  - If `PrayerFormatters.isStale(snapshot.snapshotTimestamp)`: show greyed-out times + SF Symbol `exclamationmark.triangle` warning
  - Background: `.containerBackground(.widgetBackground, for: .widget)` — NO custom colour
  - Font: `Font.custom("Cairo-Bold", size: 16)` with fallback `.system(.body)`; environment locale `ar`
  - `.widgetURL(URL(string: "tazkira://home")!)`
  - _Requirements: 3.1–3.7_

- [ ] 10. Create `MediumWidgetView.swift`
  - Create `ios/TazkiraWidget/MediumWidgetView.swift`
  - Layout (VStack):
    - Top row: Text `"الصلاة القادمة"` + Text `nextPrayerName` + Text formatted `nextPrayerTime`
    - Divider
    - HStack of 5 prayer columns (RTL: الفجر → الظهر → العصر → المغرب → العشاء):
      - Each: VStack(prayer name, formatted time)
      - Highlighted column (matches `nextPrayerName`): `.overlay(RoundedRectangle.stroke(Color.white, lineWidth: 1.5))` + full opacity; others at 0.6 opacity
  - Staleness: grey all times + warning icon if `isStale`
  - No snapshot: show `"افتح التطبيق لتحديث البيانات"`
  - Background: `.containerBackground(.widgetBackground, for: .widget)`
  - `.widgetURL(URL(string: "tazkira://home")!)`
  - _Requirements: 4.1–4.7_

- [ ] 11. Create `LargeWidgetView.swift`
  - Create `ios/TazkiraWidget/LargeWidgetView.swift`
  - Layout (VStack):
    - Text: `snapshot.hijriDate` — top, bold
    - Banner: Text `"الصلاة القادمة"` + Text `nextPrayerName` + Text formatted `nextPrayerTime`
    - Divider
    - LazyVGrid (2 columns) or HStack of 5 prayer cards: name + time, with highlight on next prayer
  - Staleness: grey times + warning icon
  - No snapshot: show `"افتح التطبيق لتحديث البيانات"`
  - Background: `.containerBackground(.widgetBackground, for: .widget)`
  - `.widgetURL(URL(string: "tazkira://home")!)`
  - _Requirements: 5.1–5.8_

- [ ] 12. Create `LockScreenWidgetView.swift`
  - Create `ios/TazkiraWidget/LockScreenWidgetView.swift`
  - **Entire file wrapped in `@available(iOS 16.0, *)`**
  - Family: `accessoryRectangular`
  - Layout (HStack): Text `"الصلاة القادمة"` + Text `nextPrayerName` + Text formatted `nextPrayerTime`
  - No snapshot: show `"— —"`
  - Background: `.containerBackground(.widgetBackground, for: .widget)` — NO custom colour, full system vibrancy
  - Text: `.foregroundStyle(.primary)` (renders as white on Lock Screen)
  - `.widgetURL(URL(string: "tazkira://home")!)`
  - _Requirements: 6.1–6.5_

- [ ] 13. Create `TazkiraWidget.swift` bundle entry point
  - Create `ios/TazkiraWidget/TazkiraWidget.swift`
  - Declare `SmallPrayerWidget` (`Widget`, family `.systemSmall`, view `SmallWidgetView`)
  - Declare `MediumPrayerWidget` (`Widget`, family `.systemMedium`, view `MediumWidgetView`)
  - Declare `LargePrayerWidget` (`Widget`, family `.systemLarge`, view `LargeWidgetView`)
  - Declare `LockScreenWidget` (`Widget`, family `.accessoryRectangular`, view `LockScreenWidgetView`) — wrapped in `@available(iOS 16.0, *)`
  - `@main struct TazkiraWidgetBundle: WidgetBundle`:
    - Always includes Small, Medium, Large widgets (iOS 14+)
    - Conditionally includes LockScreenWidget: use `@WidgetBundleBuilder` with `if #available(iOS 16.0, *)` guard
  - Widget extension deployment target: **iOS 14.0** (Lock Screen availability handled at runtime with `@available`)
  - _Requirements: 3.1, 4.1, 5.1, 6.1, 8.2–8.3_

## Phase 6: Android — Widget Implementation

- [ ] 14. Create `SnapshotReader.kt` and `PrayerFormatters.kt`
  - Create `android/app/src/main/kotlin/com/moaz/tazkira/widget/SnapshotReader.kt`:
    - `data class PrayerSnapshot(val fajr, val dhuhr, val asr, val maghrib, val isha, val nextPrayerName, val nextPrayerTime, val hijriDate, val snapshotTimestamp: String)`
    - `fun read(context: Context): PrayerSnapshot?`: reads `getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE).getString("flutter.tazkira_widget_data", null)` → parses JSON → returns null if absent or malformed
  - Create `android/app/src/main/kotlin/com/moaz/tazkira/widget/PrayerFormatters.kt`:
    - `fun formatTime(isoString: String?): String`: parse ISO-8601 UTC → local time → `"HH:mm ص/م"`; return `"—"` on any error
    - `fun isStale(isoTimestamp: String?): Boolean`: returns `true` if age > 25 hours
  - _Requirements: 13.2, 13.5, 10.4_

- [ ] 15. Create `PrayerGlanceWidget.kt`
  - Create `android/app/src/main/kotlin/com/moaz/tazkira/widget/PrayerGlanceWidget.kt`
  - Extends `GlanceAppWidget`
  - Override `provideGlance(context, id)`:
    - Read snapshot via `SnapshotReader.read(context)`
    - If null or invalid → show placeholder state: Text `"افتح التطبيق"` + `"—"` for each prayer
    - If `isStale` → render times at 0.4 alpha
    - Layout:
      ```
      Box(background: GradientBackground #5A8C8C→#7CB9AD, cornerRadius 16dp)
        Column
          Row: Text("الصلاة القادمة"), Text(nextPrayerName), Text(formatTime(nextPrayerTime))
          Row of 5 prayer columns (RTL: الفجر الظهر العصر المغرب العشاء)
            Each: Column(Text(name), Text(formatTime(time)))
            Highlighted column: white border 1.5dp, alpha 1.0; others alpha 0.6
          Text(hijriDate)
      ```
    - Tap action: `actionStartActivity<MainActivity>()`
  - Font: attempt `FontFamily(Font(R.font.cairo_bold))`; system fallback on load failure
  - `android:supportsRtl="true"` on application
  - _Requirements: 9.1–9.11_

- [ ] 16. Create `PrayerWidgetReceiver.kt`
  - Create `android/app/src/main/kotlin/com/moaz/tazkira/widget/PrayerWidgetReceiver.kt`
  - Extends `GlanceAppWidgetReceiver`
  - Override `glanceAppWidget`: returns `PrayerGlanceWidget()`
  - Override `onReceive(context, intent)`:
    - Call `super.onReceive(context, intent)`
    - If `intent.action == "com.moaz.tazkira.WIDGET_UPDATE"` or `AppWidgetManager.ACTION_APPWIDGET_UPDATE`: call `PrayerGlanceWidget().updateAll(context)` in a coroutine
  - _Requirements: 10.1–10.3_

- [ ] 17. Create `prayer_widget_info.xml` and `widget_background.xml`
  - Create `android/app/src/main/res/xml/prayer_widget_info.xml`:
    ```xml
    <appwidget-provider
      android:minWidth="180dp"
      android:minHeight="110dp"
      android:updatePeriodMillis="1800000"
      android:resizeMode="horizontal|vertical"
      android:widgetCategory="home_screen"
      android:initialLayout="@layout/glance_default_loading_layout" />
    ```
  - Create `android/app/src/main/res/drawable/widget_background.xml`: shape drawable with gradient `#5A8C8C` → `#7CB9AD`, corner radius 16dp (fallback for pre-Glance rendering)
  - _Requirements: 9.11, 10.1_

- [ ] 18. Add Cairo font assets to Android
  - **Pre-check completed**: The project uses `google_fonts: ^6.2.1` which downloads Cairo at runtime via `GoogleFonts.cairo()`. No TTF font files exist anywhere in the project assets. The native Android widget extension **cannot** use `google_fonts` — it must have the font file directly.
  - Extract `Cairo-Regular.ttf` and `Cairo-Bold.ttf` from Google Fonts cache at `~/.pub-cache/hosted/pub.dev/google_fonts-.../fonts/` or download directly from [fonts.google.com/specimen/Cairo](https://fonts.google.com/specimen/Cairo)
  - Copy as `android/app/src/main/res/font/cairo_regular.ttf` and `android/app/src/main/res/font/cairo_bold.ttf`
  - For iOS widget: the same font files must be copied into the `ios/TazkiraWidget/` target resources — the Runner app bundle's cached fonts are NOT accessible to the extension. Add both TTF files to the `TazkiraWidget` target in Xcode.
  - In both Android and iOS widget code, fall back to system Arabic font gracefully if the font file fails to load
  - _Requirements: 11.2_

## Phase 7: Android — Manifest and Build

- [ ] 19. Update `AndroidManifest.xml`
  - Add `android:supportsRtl="true"` to `<application>` element
  - Register `PrayerWidgetReceiver`:
    ```xml
    <receiver
      android:name=".widget.PrayerWidgetReceiver"
      android:exported="true">
      <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
      </intent-filter>
      <intent-filter>
        <action android:name="com.moaz.tazkira.WIDGET_UPDATE" />
      </intent-filter>
      <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/prayer_widget_info" />
    </receiver>
    ```
  - _Requirements: 9.1, 10.3_

- [ ] 20. Update `build.gradle` with Glance dependency
  - Add to `dependencies` block in `android/app/build.gradle`:
    ```groovy
    implementation "androidx.glance:glance-appwidget:1.1.1"
    implementation "androidx.glance:glance-material3:1.1.1"
    ```
  - _Requirements: 9.1_

## Phase 8: Deep Linking

- [ ] 21. Handle `tazkira://home` deep link on iOS
  - `ios/Runner/Info.plist` already updated in Task 6 with URL scheme `tazkira`
  - Modify `ios/Runner/AppDelegate.swift`: implement `application(_:open:options:)` to handle incoming `tazkira://home` URL — navigate to home (app already starts on home so simply open the app)
  - _Requirements: 12.1–12.4_

- [ ] 22. Handle deep link intent on Android
  - In `android/app/src/main/AndroidManifest.xml`, add deep-link `<intent-filter>` to `MainActivity`:
    ```xml
    <intent-filter>
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="tazkira" android:host="home" />
    </intent-filter>
    ```
  - `MainActivity` already starts with `launchMode="singleTop"` — ensures no duplicate routes
  - _Requirements: 12.1, 12.2, 12.5_

## Phase 9: Tests

- [ ] 23. Write unit tests for `PrayerDataSnapshot`
  - Create `test/core/models/prayer_data_snapshot_test.dart`
  - Test `toJson()` — assert `sunrise`, `latitude`, `longitude` keys absent
  - Test `toJson()` — assert all 9 required keys present and non-null
  - Test `fromJson()` — unknown extra keys do not throw
  - Test `contentEquals()` — two identical snapshots return `true`
  - Test `contentEquals()` — differing `nextPrayerName` returns `false`
  - Test `contentEquals()` — differing any prayer time returns `false`
  - Test `contentEquals()` — differing `hijriDate` returns `false`
  - Test `isValid()` — returns `false` when any prayer time is empty string
  - _Requirements: 13.1–13.4_

- [ ] 24. Write unit tests for `WidgetDataService`
  - Create `test/core/services/widget_data_service_test.dart`
  - Mock `MethodChannel` using `TestDefaultBinaryMessengerBinding`
  - Test: identical snapshot published twice → `reloadWidgets` called only once
  - Test: different `nextPrayerName` → `reloadWidgets` called on second publish
  - Test: `MissingPluginException` → no crash, no write, no retry scheduled
  - Test: channel throws `PlatformException` → error is logged, no crash, no retry timer; next natural call succeeds normally
  - Test: invalid snapshot (empty prayer time) → `publishSnapshot` returns without calling channel
  - _Requirements: 2.4, 2.5_

- [ ] 25. Write property-based tests
  - Create `test/core/models/prayer_data_snapshot_pbt_test.dart`
  - Use `package:test` with manual generator helpers (no external PBT library needed for simple properties)
  - **Property 1** (100 iterations): Random valid `PrayerDataSnapshot` → `toJson()` never contains `sunrise`, `latitude`, `longitude`; always contains all 9 fields non-null
  - **Property 2** (100 iterations): Random valid snapshot → `jsonEncode(jsonDecode(jsonEncode(s.toJson()))) == jsonEncode(s.toJson())`
  - **Property 3** (100 iterations): Snapshot with one random prayer time field set to empty → `isValid()` returns `false`
  - **Property 4** (100 iterations): Random ISO string or null/garbage → `formatTime()` always returns either a valid `HH:mm ص/م` string or `"—"`, never throws
  - **Property 5** (100 iterations): Two snapshots with all content fields equal → `contentEquals()` returns `true`, `_hasChanged()` returns `false`
  - _Requirements: 13.1–13.5_
