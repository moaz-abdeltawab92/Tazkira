# Requirements Document

## Introduction

This feature adds native Home Screen and Lock Screen widgets for the Tazkira (تَذْكِرَة) Flutter app on both iOS and Android platforms. The widgets display Islamic prayer times, the next upcoming prayer with a countdown, and the current Hijri date — all matching the visual identity of the existing app. Prayer times are calculated once inside the Flutter app using the same `adhan` library (Egyptian method, Shafi madhab) and shared with native widget code via platform-specific shared storage; the native widget layer never re-calculates prayer times independently.

---

## Glossary

- **Widget_Extension**: The iOS WidgetKit extension target (Swift/SwiftUI) embedded in the Xcode project that renders the Home Screen and Lock Screen widgets.
- **App_Widget**: The Android AppWidget component (Kotlin / Jetpack Glance) that renders the Home Screen widget.
- **Data_Bridge**: The Flutter-side service (`WidgetDataService`) that serialises prayer times and Hijri date into shared storage so that native widgets can read them.
- **Shared_Storage_iOS**: The iOS App Group UserDefaults container (group identifier `group.com.moaz.tazkira`) accessible by both the Runner target and the Widget_Extension.
- **Shared_Storage_Android**: The Android `SharedPreferences` file named `FlutterSharedPreferences` (the default Flutter preferences file, writable by the app and readable by the App_Widget in the same process/package).
- **Prayer_Data_Snapshot**: A serialised JSON object written to Shared_Storage containing: `fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha` times (ISO-8601 strings), `nextPrayerName` (Arabic string), `nextPrayerTime` (ISO-8601), `hijriDate` (formatted Arabic string), `hijriOffset` (integer), `snapshotTimestamp` (ISO-8601), and `latitude`/`longitude` (doubles).
- **Prayer_Names_AR**: The five obligatory Arabic prayer names used in the app and widgets — الفجر (Fajr), الظهر (Dhuhr), العصر (Asr), المغرب (Maghrib), العشاء (Isha). Sunrise (الشروق) is excluded from widget display in this release.
- **Time_Format_AR**: 12-hour Arabic format with ص (AM) / م (PM) suffix, e.g. `04:13 ص`.
- **Hijri_Date_Format**: Arabic Hijri date string as used in the app, e.g. `7 محرم 1447 هـ`.
- **Next_Prayer**: The first prayer in the ordered sequence (الفجر → الظهر → العصر → المغرب → العشاء) whose scheduled time is strictly after the current local time. If all five prayers for the current day have passed, Next_Prayer is الفجر of the following day.
- **Widget_Timeline**: The WidgetKit concept of a time-ordered sequence of entries used to pre-render widget snapshots.
- **Refresh_Trigger**: Any event — prayer time transition, day change, app foreground, or explicit user refresh — that causes the Data_Bridge to write a new Prayer_Data_Snapshot and request a widget reload.
- **Small_Widget**: A widget configuration occupying the smallest standard home-screen widget slot (iOS systemSmall, Android 2×2 grid cells).
- **Medium_Widget**: A widget configuration occupying the medium standard home-screen widget slot (iOS systemMedium, Android 4×2 grid cells).
- **Large_Widget**: A widget configuration occupying the large standard home-screen widget slot (iOS systemLarge, Android 4×4 grid cells).
- **Lock_Screen_Widget**: An iOS widget rendered in the Lock Screen accessory area (accessoryRectangular / accessoryCircular / accessoryInline families, iOS 16+).
- **Highlight_Style**: A visual distinction (border, elevated opacity, or accent color) applied to the card of the Next_Prayer among all displayed prayer cards.
- **Vibrancy_Effect**: The iOS `.widgetBackground` + `.widgetAccentable` material that allows the Lock Screen wallpaper to show through the widget background.
- **App_Color_Teal**: Primary teal gradient — `#5A8C8C` → `#7CB9AD` — used in the app's Hijri date card and Dhuhr prayer card.
- **App_Color_Navy**: Dark navy gradient — `#1B3A4B` → `#2C5364` — used in the app's Isha prayer card.
- **Cairo_Font**: The Google Fonts "Cairo" typeface used throughout the app for Arabic text.

---

## Requirements

### Requirement 1: Data Bridge — Snapshot Writing

**User Story:** As the Tazkira app, I want to write the current prayer times and Hijri date to shared storage whenever data changes, so that native widgets always display accurate, up-to-date information without needing to perform their own calculations.

#### Acceptance Criteria

1. THE Data_Bridge SHALL expose a public `writeSnapshot()` method that calculates the full day's prayer times for the device's current GPS coordinates using `CalculationMethod.egyptian` with `Madhab.shafi` and serialises the result as a Prayer_Data_Snapshot into Shared_Storage_iOS (on iOS) or Shared_Storage_Android (on Android).
2. WHEN the Flutter app enters the foreground (`AppLifecycleState.resumed`), THE Data_Bridge SHALL call `writeSnapshot()` within 3 seconds.
3. WHEN the Flutter app cold-starts, THE Data_Bridge SHALL initiate `writeSnapshot()` during `initState` of the root widget; IF the calculation takes longer than one frame, THEN THE Data_Bridge SHALL allow `writeSnapshot()` to complete asynchronously after the first frame renders.
4. WHEN a prayer time passes and the Next_Prayer changes (detected by the existing one-minute timer in `PrayerTimesCardsWidget`), THE Data_Bridge SHALL call `writeSnapshot()` within 90 seconds of the transition.
5. WHEN the local calendar date changes (midnight transition detected by the existing timer), THE Data_Bridge SHALL call `writeSnapshot()` to refresh all prayer times for the new day.
6. WHEN the user changes the Hijri date offset in settings (key `hijri_date_offset` in SharedPreferences), THE Data_Bridge SHALL call `writeSnapshot()` within 1 second of the change being saved.
7. IF location permission is permanently denied, THEN THE Data_Bridge SHALL retain the most recently written Prayer_Data_Snapshot in Shared_Storage and SHALL NOT retry GPS acquisition. WHEN location permission is granted but GPS coordinates are temporarily unavailable, THE Data_Bridge SHALL retry GPS acquisition at 30-second intervals for up to 5 minutes before falling back to the cached coordinates.
8. THE Prayer_Data_Snapshot SHALL contain the fields: `fajr`, `dhuhr`, `asr`, `maghrib`, `isha` (ISO-8601 UTC strings — five obligatory prayers only; `sunrise` is excluded from widget display), `nextPrayerName` (Arabic string from Prayer_Names_AR), `nextPrayerTime` (ISO-8601 UTC string), `hijriDate` (Hijri_Date_Format string), `snapshotTimestamp` (ISO-8601 UTC string), `latitude` (double), `longitude` (double).
9. THE Data_Bridge SHALL use the `flutter_app_group_directory` package (or equivalent) on iOS to write to Shared_Storage_iOS under the key `tazkira_widget_data`.
10. THE Data_Bridge SHALL write to Shared_Storage_Android under the SharedPreferences key `flutter.tazkira_widget_data` so that the App_Widget can read it from the same `FlutterSharedPreferences` file.

---

### Requirement 2: Data Bridge — Widget Reload Trigger

**User Story:** As a native widget, I want to be told when new data is available, so that my display refreshes promptly rather than waiting for the OS-scheduled update interval.

#### Acceptance Criteria

1. WHEN `writeSnapshot()` completes successfully on iOS, THE Data_Bridge SHALL invoke the WidgetKit `WidgetCenter.reloadAllTimelines()` API via a platform channel to request an immediate Widget_Timeline reload.
2. WHEN `writeSnapshot()` completes successfully on Android, THE Data_Bridge SHALL broadcast the Android `AppWidgetManager.ACTION_APPWIDGET_UPDATE` intent (or invoke the equivalent Jetpack Glance API) via a platform channel to request an App_Widget refresh.
3. THE Data_Bridge SHALL implement the platform channel calls using a method channel named `com.moaz.tazkira/widget_channel`.
4. IF a platform channel call fails (e.g., widget extension not installed), THEN THE Data_Bridge SHALL log the error, retry the call once after 5 seconds, and continue without crashing the Flutter app if the retry also fails.
5. IF the platform channel subsystem is completely unavailable (e.g., `MissingPluginException`), THEN THE Data_Bridge SHALL fall back to writing directly to SharedPreferences without requesting a widget reload, so that the widget receives updated data on its next OS-scheduled refresh cycle.

---

### Requirement 3: iOS Widget — Small Configuration (Next Prayer)

**User Story:** As a user who added the small Tazkira widget to my iPhone Home Screen, I want to see the next prayer name and time at a glance, so that I never miss a prayer.

#### Acceptance Criteria

1. THE Widget_Extension SHALL provide a Small_Widget configuration named "Tazkira – الصلاة القادمة".
2. WHEN the Small_Widget renders, THE Widget_Extension SHALL read the Prayer_Data_Snapshot from Shared_Storage_iOS and display a label "الصلاة القادمة", the `nextPrayerName`, and the `nextPrayerTime` (formatted as Time_Format_AR) stacked vertically in the centre of the widget. No countdown or remaining-time value SHALL be displayed.
3. THE Small_Widget SHALL display the app icon or a mosque SF Symbol icon above the prayer name to identify the app visually.
4. WHEN no Prayer_Data_Snapshot exists in Shared_Storage_iOS, THE Widget_Extension SHALL display the placeholder text "افتح التطبيق لتحديث البيانات" in the Small_Widget.
5. THE Small_Widget background SHALL use `.widgetBackground` container background with no custom colour or gradient, allowing the system and wallpaper to define the background appearance naturally, consistent with Apple's native widget style.
6. THE Small_Widget SHALL use the Cairo_Font (or the system Arabic font as fallback) for all Arabic text.
7. WHEN the user taps the Small_Widget, THE Widget_Extension SHALL open the Tazkira app via a deep-link URL `tazkira://home`; IF the deep-link fails to resolve, THEN THE Widget_Extension SHALL fall back to launching the app via its bundle identifier without a specific URL.

---

### Requirement 4: iOS Widget — Medium Configuration (All Prayers)

**User Story:** As a user who added the medium Tazkira widget to my Home Screen, I want to see the next prayer prominently and all five obligatory prayer times in a row, so that I can plan my day around prayer times at a glance.

#### Acceptance Criteria

1. THE Widget_Extension SHALL provide a Medium_Widget configuration named "Tazkira – أوقات الصلاة".
2. WHEN the Medium_Widget renders, THE Widget_Extension SHALL display a top section showing "الصلاة القادمة", `nextPrayerName`, and `nextPrayerTime` (formatted as Time_Format_AR) with no countdown or remaining-time value.
3. THE Medium_Widget SHALL display five prayer columns below the next-prayer section, in RTL order (الفجر → الظهر → العصر → المغرب → العشاء from right to left), each showing the prayer name and its time formatted as Time_Format_AR. Sunrise (الشروق) SHALL NOT be displayed.
4. THE Medium_Widget SHALL apply the Highlight_Style to the column whose prayer name matches `nextPrayerName` in the Prayer_Data_Snapshot. IF the highlight logic encounters an exception, THEN THE Medium_Widget SHALL display all prayer columns without highlighting rather than failing to render.
5. WHEN no Prayer_Data_Snapshot exists in Shared_Storage_iOS, THE Widget_Extension SHALL display the placeholder text "افتح التطبيق لتحديث البيانات" in the Medium_Widget.
6. THE Medium_Widget background SHALL use `.widgetBackground` container background with no custom colour or gradient, consistent with Apple's native widget style.
7. WHEN the user taps the Medium_Widget, THE Widget_Extension SHALL open the Tazkira app via deep-link URL `tazkira://home`; IF the deep-link fails to resolve, THEN THE Widget_Extension SHALL fall back to launching the app via its bundle identifier.

---

### Requirement 5: iOS Widget — Large Configuration (All Prayers + Hijri Date)

**User Story:** As a user who added the large Tazkira widget to my Home Screen, I want to see all five obligatory prayer times, the current Hijri date, and the next prayer prominently, so that I have my full Islamic daily schedule at a glance.

#### Acceptance Criteria

1. THE Widget_Extension SHALL provide a Large_Widget configuration named "Tazkira – الجدول اليومي".
2. WHEN the Large_Widget renders, THE Widget_Extension SHALL display the `hijriDate` string from the Prayer_Data_Snapshot at the top of the widget.
3. THE Large_Widget SHALL display "الصلاة القادمة", `nextPrayerName`, and `nextPrayerTime` in a prominent banner below the Hijri date. No countdown or remaining-time value SHALL be displayed.
4. THE Large_Widget SHALL display the five obligatory prayer cards (الفجر, الظهر, العصر, المغرب, العشاء) below the banner, each showing the prayer name and time formatted as Time_Format_AR. Sunrise (الشروق) SHALL NOT be displayed.
5. THE Large_Widget SHALL apply the Highlight_Style to the card whose prayer name matches `nextPrayerName`. IF the highlight logic encounters an exception, THE Large_Widget SHALL display all prayer cards without highlighting rather than failing to render.
6. WHEN no Prayer_Data_Snapshot exists in Shared_Storage_iOS, THE Widget_Extension SHALL display the placeholder text "افتح التطبيق لتحديث البيانات" in the Large_Widget.
7. THE Large_Widget background SHALL use `.widgetBackground` container background with no custom colour or gradient, consistent with Apple's native widget style.
8. WHEN the user taps the Large_Widget, THE Widget_Extension SHALL open the Tazkira app via deep-link URL `tazkira://home`; IF the deep-link fails to resolve, THEN THE Widget_Extension SHALL fall back to launching the app via its bundle identifier.

---

### Requirement 6: iOS Widget — Lock Screen Configuration

**User Story:** As a user who customised my iPhone Lock Screen (iOS 16+), I want to add a Tazkira accessory widget showing the next prayer, so that I can see the next prayer without unlocking my phone.

#### Acceptance Criteria

1. THE Widget_Extension SHALL provide a Lock_Screen_Widget using the `accessoryRectangular` family that displays "الصلاة القادمة", `nextPrayerName`, and `nextPrayerTime` (formatted as Time_Format_AR). No countdown or remaining-time value SHALL be displayed.
2. THE Widget_Extension SHALL apply `Vibrancy_Effect` (`.widgetBackground` with no custom colour or gradient) to the Lock_Screen_Widget so that the Lock Screen wallpaper shows through naturally, matching Apple's native Lock Screen widget style.
3. THE Lock_Screen_Widget SHALL use white or system-vibrancy-rendered text for all labels.
4. WHEN no Prayer_Data_Snapshot exists in Shared_Storage_iOS, THE Widget_Extension SHALL display "—" placeholders for prayer name and time in the Lock_Screen_Widget.
5. WHEN the user taps the Lock_Screen_Widget, THE Widget_Extension SHALL open the Tazkira app via deep-link URL `tazkira://home`; IF the deep-link fails to resolve, THEN THE Widget_Extension SHALL fall back to launching the app normally via its bundle identifier. THE widget SHALL allow the tap to fail silently only in exceptional system conditions (e.g., OS-level app-launch failure) that are outside the widget's control.

---

### Requirement 7: iOS Widget — Timeline and Refresh Policy

**User Story:** As an iOS widget, I want to refresh my timeline at each prayer transition and at midnight so that the displayed times are always current without draining the battery.

#### Acceptance Criteria

1. THE Widget_Extension SHALL build a Widget_Timeline containing one entry per remaining prayer transition for the current day, plus one entry at midnight for the day change.
2. WHEN the Widget_Timeline is exhausted (all entries have been delivered), THE Widget_Extension SHALL request a reload after 60 minutes (`.atEnd` reload policy with a `nextReloadDate` no sooner than 60 minutes in the future).
3. WHEN the Data_Bridge calls `WidgetCenter.reloadAllTimelines()` via the platform channel, THE Widget_Extension SHALL rebuild its Widget_Timeline from the latest Prayer_Data_Snapshot immediately.
4. IF the Prayer_Data_Snapshot `snapshotTimestamp` is strictly older than 25 hours (i.e., the age exceeds 25 hours; a snapshot exactly 25 hours old SHALL NOT trigger the indicator), THEN THE Widget_Extension SHALL display a staleness indicator (e.g., a small warning icon or greyed-out times) instead of showing potentially incorrect times.

---

### Requirement 8: iOS App Group and Entitlements

**User Story:** As the iOS build system, I want the Runner target and Widget Extension target to share an App Group, so that the Data_Bridge can write data that the Widget_Extension can read.

#### Acceptance Criteria

1. THE Xcode project SHALL declare the App Group entitlement `group.com.moaz.tazkira` in both the Runner target and the Widget_Extension target.
2. THE Widget_Extension target SHALL have its own `Info.plist` with `NSExtension` dictionary specifying `NSExtensionPointIdentifier` as `com.apple.widgetkit-extension`.
3. THE Widget_Extension target SHALL be linked against the `WidgetKit` and `SwiftUI` frameworks.
4. THE Widget_Extension SHALL target iOS 16.0 as its minimum deployment target (to support Lock Screen widgets).
5. THE Runner target's `Info.plist` SHALL declare the `tazkira` URL scheme under `CFBundleURLTypes` so that deep links from widget taps open the correct app.

---

### Requirement 9: Android Widget — Home Screen AppWidget

**User Story:** As an Android user who added the Tazkira widget to my Home Screen, I want to see the next prayer, all five prayer times, and the Hijri date with the app's colour palette, so that I can check prayer times without opening the app.

#### Acceptance Criteria

1. THE App_Widget SHALL be implemented using Jetpack Glance (minimum API level 23) and registered as an `AppWidgetProvider` in `AndroidManifest.xml` with the action `android.appwidget.action.APPWIDGET_UPDATE`.
2. THE App_Widget SHALL read the Prayer_Data_Snapshot from Shared_Storage_Android on each update cycle.
3. WHEN the App_Widget renders, THE App_Widget SHALL display a label "الصلاة القادمة", the `nextPrayerName`, and `nextPrayerTime` (formatted as Time_Format_AR) in a full-width section at the top of the widget. No countdown or remaining-time value SHALL be displayed.
4. THE App_Widget SHALL display all five obligatory prayer times (الفجر, الظهر, العصر, المغرب, العشاء) in a horizontal row, each showing the prayer name and time formatted as Time_Format_AR. Sunrise (الشروق) SHALL NOT be displayed.
5. THE App_Widget SHALL display the `hijriDate` string below the prayer row.
6. THE App_Widget SHALL apply the Highlight_Style to the prayer column whose name matches `nextPrayerName` in the Prayer_Data_Snapshot; IF the highlight logic encounters a technical error, THE App_Widget SHALL display all prayer columns without highlighting rather than failing to render.
7. THE App_Widget background SHALL use the App_Color_Teal gradient (`#5A8C8C` → `#7CB9AD`) with rounded corners of 16dp.
8. THE App_Widget SHALL use white text for all labels.
9. WHEN no Prayer_Data_Snapshot exists in Shared_Storage_Android or when the snapshot data is determined to be invalid or unreliable, THE App_Widget SHALL display the placeholder text "افتح التطبيق" in the header section and placeholder "—" values for individual prayer times.
10. WHEN the user taps anywhere on the App_Widget, THE App_Widget SHALL launch the Tazkira app's main activity (`com.moaz.tazkira.MainActivity`).
11. THE App_Widget SHALL declare `android:resizeMode="horizontal|vertical"` and `android:minWidth="180dp"` and `android:minHeight="110dp"` in its `AppWidgetProviderInfo` XML.

---

### Requirement 10: Android Widget — Update Scheduling

**User Story:** As the Android widget system, I want to receive update broadcasts at each prayer transition so that the displayed prayer is always current.

#### Acceptance Criteria

1. THE App_Widget SHALL set `android:updatePeriodMillis` to `1800000` (30 minutes) in its `AppWidgetProviderInfo` XML as a baseline OS-level update interval.
2. WHEN the Data_Bridge broadcasts `ACTION_APPWIDGET_UPDATE` via the platform channel, THE App_Widget SHALL immediately re-read Shared_Storage_Android and re-render.
3. THE App_Widget SHALL register a `BroadcastReceiver` named `PrayerWidgetReceiver` that listens for the custom action `com.moaz.tazkira.WIDGET_UPDATE` to handle explicit refresh requests from the Data_Bridge.
4. IF the Prayer_Data_Snapshot `snapshotTimestamp` is strictly older than 25 hours (i.e., the age exceeds 25 hours; a snapshot exactly 25 hours old SHALL NOT trigger greying out), THEN THE App_Widget SHALL display greyed-out prayer times to indicate the data may be stale. IF the `snapshotTimestamp` field is absent or unparseable, THE App_Widget SHALL display the placeholder state rather than greying out.

---

### Requirement 11: Widget Visual Design — Highlight and Typography

**User Story:** As a user glancing at the widget, I want the next upcoming prayer to stand out visually and all text to be legible in Arabic, so that I can identify the next prayer instantly.

#### Acceptance Criteria

1. THE Highlight_Style applied to the Next_Prayer column/card SHALL include a white border of at least 1.5pt/dp width and a background opacity of 100% (compared to 60% opacity for non-highlighted prayers), matching the existing `_buildPrayerCard` logic in `PrayerTimesCardsWidget`.
2. THE App_Widget and Widget_Extension SHALL render prayer names using the Cairo_Font (embedded as a custom font asset) after explicitly verifying the font is available; WHEN the Cairo_Font is detected as unavailable, THE widget SHALL use the system Arabic font and SHALL NOT attempt to load Cairo_Font to avoid rendering failures.
3. THE App_Widget and Widget_Extension SHALL render prayer times using Time_Format_AR (12-hour, Arabic AM/PM suffix ص / م).
4. THE Widget_Extension SHALL render all Arabic text with right-to-left layout directionality.
5. THE App_Widget SHALL set `android:supportsRtl="true"` and use RTL layout order for prayer columns.

---

### Requirement 12: Deep Linking — App Open from Widget Tap

**User Story:** As a user who taps the widget, I want to be taken directly to the prayer times screen in the Tazkira app, so that I can see full detail without navigating manually.

#### Acceptance Criteria

1. WHEN the Flutter app is not running or is in the background and a widget tap opens the app via the `tazkira://home` deep link, THE Flutter app SHALL launch normally and navigate to the Home Screen (the screen containing `PrayerTimesCardsWidget` and `HijriDateCard`).
2. WHEN the app is already in the foreground and a widget tap arrives, THE Flutter app SHALL bring the Home Screen to the front without creating a duplicate route.
3. THE Flutter app SHALL register the `tazkira` URL scheme in `ios/Runner/Info.plist` under `CFBundleURLTypes` with `CFBundleURLSchemes` containing `tazkira`; THE Flutter app SHALL handle incoming URLs only after the `tazkira` scheme is registered in the plist configuration.
4. THE Flutter app SHALL handle the incoming URL in `AppDelegate.swift` (or via the `app_links` / `uni_links` package) and route to the home screen.
5. THE Flutter app SHALL handle the Android intent launched from `MainActivity` with the widget tap and route to the home screen.

---

### Requirement 13: Prayer Times Serialisation Round-Trip

**User Story:** As the Data_Bridge, I want to guarantee that serialised prayer times can be deserialised back to the same values, so that the widget never displays incorrect times due to encoding errors.

#### Acceptance Criteria

1. THE Data_Bridge SHALL serialise each prayer DateTime as an ISO-8601 UTC string (e.g., `"2025-07-14T02:13:00.000Z"`).
2. THE Data_Bridge SHALL deserialise the ISO-8601 UTC string back to a local DateTime and re-format it as Time_Format_AR before display.
3. FOR ALL valid Prayer_Data_Snapshots serialised by the Data_Bridge, parsing the JSON string and re-serialising it SHALL produce an equivalent JSON string (round-trip property).
4. THE Data_Bridge SHALL validate that all five prayer time fields (`fajr`, `dhuhr`, `asr`, `maghrib`, `isha`) are present and non-null in the Prayer_Data_Snapshot before writing to Shared_Storage. The `sunrise` field SHALL NOT be included in the snapshot written for widget consumption.
5. IF any prayer time field is null or unparseable during deserialisation by the native widget, THEN THE Widget_Extension and THE App_Widget SHALL display "—" for that prayer's time slot rather than crashing.

---

### Requirement 14: Hijri Date in Widget

**User Story:** As a user, I want the widget to show the Hijri date with the same user-adjustable offset that I set in the app settings, so that the widget date matches what I see inside the app.

#### Acceptance Criteria

1. THE Data_Bridge SHALL read the `hijri_date_offset` value from SharedPreferences (range −2 to +2, default 0) and include the adjusted Hijri date string in the Prayer_Data_Snapshot as `hijriDate` using Hijri_Date_Format.
2. THE Widget_Extension and THE App_Widget SHALL display the `hijriDate` string from the Prayer_Data_Snapshot without re-computing the Hijri date natively, provided the Prayer_Data_Snapshot is available and the `hijriDate` field is non-empty. WHEN no Prayer_Data_Snapshot is available, THE Widget_Extension and THE App_Widget SHALL display "—" for the Hijri date rather than computing it natively.
3. WHEN the user changes the `hijri_date_offset` in app settings, THE Data_Bridge SHALL write a new Prayer_Data_Snapshot with the updated `hijriDate` within 1 second, and the widget SHALL reflect the new date on its next render cycle.

---

### Requirement 15: Graceful Degradation and Error States

**User Story:** As a user, I want the widget to always show something meaningful even when data is unavailable or stale, so that it never displays a blank or broken widget.

#### Acceptance Criteria

1. WHEN the App_Widget or Widget_Extension cannot read or parse the Prayer_Data_Snapshot from Shared_Storage, THE widget SHALL display the placeholder text "افتح التطبيق لتحديث البيانات" and the app icon.
2. IF the device is in Airplane Mode or location services are disabled when `writeSnapshot()` is called, THEN THE Data_Bridge SHALL use the last known GPS coordinates cached in SharedPreferences (key `last_known_latitude` / `last_known_longitude`) to calculate prayer times.
3. THE Data_Bridge SHALL cache the last successfully obtained GPS coordinates in SharedPreferences after every successful `writeSnapshot()` call.
4. WHILE the Flutter app is loading prayer times for the first time (no cached coordinates available), or WHEN cached coordinates are corrupted or invalid (e.g., latitude outside −90..90 or longitude outside −180..180), THE Data_Bridge SHALL write a Prayer_Data_Snapshot with all time fields set to `null` and `nextPrayerName` set to `""` so that the widget displays the placeholder state rather than stale data.

---

### Requirement 16: Platform Channel — Widget Communication

**User Story:** As the Flutter app, I want a single, well-defined platform channel interface for widget communication on both iOS and Android, so that the Data_Bridge implementation is maintainable and testable.

#### Acceptance Criteria

1. THE Data_Bridge SHALL use the `MethodChannel` named `com.moaz.tazkira/widget_channel` for all native widget communication.
2. THE channel SHALL support the following methods: `writeWidgetData(Map<String, dynamic> data)` → `bool` (success), `reloadWidgets()` → `void`, `isWidgetInstalled()` → `bool`.
3. THE native iOS handler SHALL implement `writeWidgetData` by writing the JSON payload to Shared_Storage_iOS and returning `true` on success.
4. THE native Android handler SHALL implement `writeWidgetData` by writing the JSON string to Shared_Storage_Android and returning `true` on success.
5. WHEN `reloadWidgets()` is called on iOS, THE native handler SHALL call `WidgetCenter.shared.reloadAllTimelines()`.
6. WHEN `reloadWidgets()` is called on Android, THE native handler SHALL call `GlanceAppWidgetManager.getInstance(context).requestPinAppWidget(...)` or send the update broadcast to the `PrayerWidgetReceiver`.
7. IF a MethodChannel call is made on a platform that does not support widgets (e.g., web, desktop), THEN THE Data_Bridge SHALL catch the `MissingPluginException` and proceed silently.
