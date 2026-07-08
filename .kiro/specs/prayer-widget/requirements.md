# Requirements Document

## Introduction

This feature adds native home screen and lock screen widgets to the Tazkira Islamic app (تَذْكِرَة) for both iOS and Android. The widgets display the next upcoming prayer, all five daily prayer times, and the Hijri date — all without opening the app. On iOS, the widget is built with WidgetKit and SwiftUI; on Android, it uses AppWidgetProvider and RemoteViews. A Flutter-side data bridge writes pre-calculated prayer and Hijri data to platform-shared storage so the native widgets can read it without duplicating any calculation logic.

## Glossary

- **Widget_Extension**: The iOS WidgetKit extension target (Swift/SwiftUI) that renders the home screen and lock screen widget.
- **Widget_Provider**: The Android `AppWidgetProvider` Kotlin class that receives system broadcasts and updates the home screen widget.
- **Data_Bridge**: The Flutter Dart class (`WidgetDataBridge`) responsible for computing widget data and writing it to platform-shared storage.
- **App_Group**: The iOS App Group container (`group.com.moaz.tazkira`) used to share data between the Runner app and the Widget_Extension via `UserDefaults(suiteName:)`.
- **Shared_Prefs_Widget**: The Android `SharedPreferences` file named `FlutterSharedPreferences` accessible to both Flutter and the Widget_Provider via the application context.
- **Widget_Data_JSON**: The serialized JSON string stored under the key `widget_prayer_data` in both App_Group (iOS) and Shared_Prefs_Widget (Android), containing all prayer times, next prayer info, and Hijri date.
- **PrayerTimesService**: The existing Dart class at `lib/features/home/services/prayer_times_service.dart` that calculates prayer times using the `adhan` package.
- **IslamicSeasonHelper**: The existing Dart class at `lib/core/utils/islamic_season_helper.dart` that returns the Hijri date adjusted for the user's stored offset.
- **Next_Prayer**: The first of the five canonical prayers (الفجر، الظهر، العصر، المغرب، العشاء) whose time is strictly after the current time; or tomorrow's Fajr if all five have passed today.
- **Upcoming_Prayer_Highlight**: A visual indicator (bold text, accent color, or glow border) distinguishing the Next_Prayer from the other four prayers in the widget UI.
- **Small_Widget**: An iOS widget conforming to `WidgetFamily.systemSmall` (approximately 2×2 icon grid cells).
- **Medium_Widget**: An iOS widget conforming to `WidgetFamily.systemMedium` (approximately 4×2 icon grid cells).
- **Large_Widget**: An iOS widget conforming to `WidgetFamily.systemLarge` (approximately 4×4 icon grid cells).
- **Lock_Screen_Widget**: An iOS widget conforming to `WidgetFamily.accessoryRectangular` displayed on the iPhone lock screen.
- **Resizable_Android_Widget**: An Android widget whose `minResizeWidth`, `minResizeHeight`, `resizeMode` attributes allow the user to drag-resize it on the home screen.
- **Teal_Palette**: The app's brand colors — dark teal `#1B5E5E`, mid teal `#5A8C8C`, light teal `#7CB9AD` — used as the Android widget background gradient.

---

## Requirements

### Requirement 1: Data Bridge — Serialize and Write Widget Data

**User Story:** As a user, I want the app to keep the widget's prayer data current so that the times displayed on my home screen are always accurate for my location and Hijri date preference.

#### Acceptance Criteria

1. THE Data_Bridge SHALL expose a single public method `refreshWidgetData(Coordinates coordinates)` that callers invoke to update widget data.
2. WHEN `refreshWidgetData` is called, THE Data_Bridge SHALL invoke `PrayerTimesService.getNextPrayerInfo(coordinates)` to obtain next-prayer information without re-implementing prayer calculation logic.
3. WHEN `refreshWidgetData` is called, THE Data_Bridge SHALL invoke `IslamicSeasonHelper.getAdjustedHijriDate()` to obtain the Hijri date without re-implementing Hijri calculation logic.
4. WHEN `refreshWidgetData` is called, THE Data_Bridge SHALL calculate all five daily prayer times (الفجر، الظهر، العصر، المغرب، العشاء) using `CalculationMethod.egyptian` with `Madhab.shafi` for the supplied coordinates and today's date.
5. THE Data_Bridge SHALL serialize the following fields into Widget_Data_JSON:
   - `prayers`: array of objects, each with `name` (Arabic string) and `time` (ISO-8601 UTC string) for all five prayers.
   - `nextPrayerName`: Arabic string identifying the Next_Prayer.
   - `nextPrayerTime`: ISO-8601 UTC string for the Next_Prayer time.
   - `hijriDay`: integer day of Hijri month.
   - `hijriMonth`: integer month of Hijri year.
   - `hijriYear`: integer Hijri year.
   - `hijriMonthName`: Arabic month name string.
   - `updatedAt`: ISO-8601 UTC string recording when the data was written.
6. WHEN running on iOS, THE Data_Bridge SHALL write Widget_Data_JSON to the App_Group container under the key `widget_prayer_data` using the `home_widget` package or a platform channel.
7. WHEN running on Android, THE Data_Bridge SHALL write Widget_Data_JSON to Shared_Prefs_Widget under the key `flutter.widget_prayer_data`.
8. AFTER writing Widget_Data_JSON on iOS, THE Data_Bridge SHALL call `WidgetCenter.reloadAllTimelines()` (via method channel or `home_widget` package) to trigger a Widget_Extension refresh.
9. AFTER writing Widget_Data_JSON on Android, THE Data_Bridge SHALL send `AppWidgetManager.ACTION_APPWIDGET_UPDATE` broadcast to notify Widget_Provider to redraw.
10. IF `PrayerTimesService.getNextPrayerInfo` returns null, THEN THE Data_Bridge SHALL log the error and abort the write operation without overwriting previously stored data.
11. IF an exception occurs during the write operation, THEN THE Data_Bridge SHALL log the error and leave the platform storage in its previous state.

---

### Requirement 2: Update Triggers — Automatic Widget Refresh

**User Story:** As a user, I want the widget to refresh automatically at key moments so I always see accurate, up-to-date prayer times without manually opening the app.

#### Acceptance Criteria

1. WHEN the app transitions to the `AppLifecycleState.resumed` foreground state, THE Data_Bridge SHALL be invoked to refresh widget data.
2. WHEN a prayer time is reached (i.e., the system clock passes `nextPrayerTime`), THE Data_Bridge SHALL be invoked to refresh widget data so the Next_Prayer advances to the following prayer.
3. WHEN the device clock crosses local midnight (00:00), THE Data_Bridge SHALL be invoked to refresh widget data so prayer times are recalculated for the new day.
4. WHEN the app first launches (before the first frame is rendered), THE Data_Bridge SHALL be invoked to refresh widget data.
5. THE Update_Scheduler SHALL schedule a Dart timer that fires at each `nextPrayerTime` + 1 second to trigger Acceptance Criterion 2, and cancel any previously active timer before scheduling a new one.
6. THE Update_Scheduler SHALL schedule a Dart timer that fires at the next local midnight to trigger Acceptance Criterion 3, and cancel any previously active timer when the app is paused.
7. IF location permission is denied when an update trigger fires, THEN THE Data_Bridge SHALL skip the refresh and retain the most recently written Widget_Data_JSON.

---

### Requirement 3: iOS WidgetKit Widget — Small Size

**User Story:** As an iOS user, I want a small home screen widget so I can see the next prayer name and time at a glance without unlocking my phone.

#### Acceptance Criteria

1. THE Widget_Extension SHALL provide a `WidgetConfiguration` supporting `WidgetFamily.systemSmall`.
2. WHEN Widget_Data_JSON is available, THE Small_Widget SHALL display the Next_Prayer name in Arabic.
3. WHEN Widget_Data_JSON is available, THE Small_Widget SHALL display the Next_Prayer time formatted as 12-hour with Arabic AM/PM (ص/م).
4. THE Small_Widget SHALL apply a transparent/vibrancy background using `.widgetBackground(Color.clear)` and `ContainerRelativeShape` so the user's wallpaper shows through.
5. THE Small_Widget SHALL use the `.widgetAccentable` modifier on the prayer name text to respect the user's widget tint color.
6. WHEN Widget_Data_JSON is absent or malformed, THE Small_Widget SHALL display a placeholder label "جاري التحميل" in place of the prayer name and time.
7. THE Widget_Extension SHALL read Widget_Data_JSON from the App_Group container at init time using `UserDefaults(suiteName: "group.com.moaz.tazkira")`.

---

### Requirement 4: iOS WidgetKit Widget — Medium Size

**User Story:** As an iOS user, I want a medium home screen widget so I can see all five prayer times and which prayer is next.

#### Acceptance Criteria

1. THE Widget_Extension SHALL provide a `WidgetConfiguration` supporting `WidgetFamily.systemMedium`.
2. WHEN Widget_Data_JSON is available, THE Medium_Widget SHALL display all five prayer names (الفجر، الظهر، العصر، المغرب، العشاء) with their times in 12-hour Arabic format in a horizontal row.
3. THE Medium_Widget SHALL apply Upcoming_Prayer_Highlight (bold font weight and white foreground) to the Next_Prayer entry.
4. WHEN Widget_Data_JSON is available, THE Medium_Widget SHALL display the Next_Prayer name and time in a header row above the five-prayer row.
5. THE Medium_Widget SHALL apply a transparent/vibrancy background identical to the Small_Widget.
6. WHEN Widget_Data_JSON is absent or malformed, THE Medium_Widget SHALL render each prayer slot as a placeholder dash "—".

---

### Requirement 5: iOS WidgetKit Widget — Large Size

**User Story:** As an iOS user, I want a large home screen widget so I can see all five prayers, the next prayer prominently, and the Hijri date.

#### Acceptance Criteria

1. THE Widget_Extension SHALL provide a `WidgetConfiguration` supporting `WidgetFamily.systemLarge`.
2. WHEN Widget_Data_JSON is available, THE Large_Widget SHALL display all five prayer names and times in a vertical list with larger font sizes than the Medium_Widget.
3. THE Large_Widget SHALL apply Upcoming_Prayer_Highlight (bold font weight, accent border, and `.widgetAccentable` tint) to the Next_Prayer row.
4. WHEN Widget_Data_JSON is available, THE Large_Widget SHALL display the Hijri date string (e.g., "15 رمضان 1446 هـ") in a footer row below the prayer list.
5. THE Large_Widget SHALL apply a transparent/vibrancy background.
6. WHEN Widget_Data_JSON is absent or malformed, THE Large_Widget SHALL render placeholder dashes for prayer rows and an empty string for the Hijri date.

---

### Requirement 6: iOS WidgetKit Widget — Lock Screen (Accessory Rectangular)

**User Story:** As an iOS 16+ user, I want a lock screen widget so I can see the next prayer without unlocking my phone.

#### Acceptance Criteria

1. THE Widget_Extension SHALL provide a `WidgetConfiguration` supporting `WidgetFamily.accessoryRectangular` and SHALL be guarded with `@available(iOS 16.0, *)`.
2. WHEN Widget_Data_JSON is available, THE Lock_Screen_Widget SHALL display the Next_Prayer name and time on a single line.
3. THE Lock_Screen_Widget SHALL use system fonts and respect the lock screen rendering environment (no color backgrounds).
4. WHEN Widget_Data_JSON is absent, THE Lock_Screen_Widget SHALL display the placeholder text "الصلاة القادمة".

---

### Requirement 7: iOS WidgetKit Widget — Timeline and Refresh Policy

**User Story:** As an iOS user, I want the widget to show accurate times even when I haven't opened the app recently, so the displayed prayer times are never stale.

#### Acceptance Criteria

1. THE Widget_Extension's `TimelineProvider` SHALL generate a timeline with one `TimelineEntry` per prayer time for the current day plus Fajr of the next day (6 entries total).
2. THE Widget_Extension's `TimelineProvider` SHALL set the `TimelineReloadPolicy` to `.atEnd` so WidgetKit requests a new timeline after the last entry elapses.
3. WHEN the app writes new Widget_Data_JSON, THE Widget_Extension SHALL call `WidgetCenter.shared.reloadAllTimelines()` to invalidate the current timeline and pull fresh data.
4. THE Widget_Extension's `TimelineProvider` SHALL parse Widget_Data_JSON from App_Group in `getTimeline(in:completion:)` and SHALL NOT perform any prayer-time calculations itself.
5. IF Widget_Data_JSON is absent when `getTimeline` is called, THE Widget_Extension SHALL generate a single placeholder entry with `.never` reload policy until the app writes valid data.

---

### Requirement 8: Android App Widget — Layout and Display

**User Story:** As an Android user, I want a home screen widget that shows all five prayer times and highlights the next prayer using the app's visual style.

#### Acceptance Criteria

1. THE Widget_Provider SHALL register an `AppWidgetProviderInfo` XML with `minWidth="250dp"`, `minHeight="110dp"`, `resizeMode="horizontal|vertical"`, and `updatePeriodMillis="0"` (updates handled by the app).
2. WHEN Widget_Data_JSON is available, THE Widget_Provider SHALL render all five prayer names and times in a `RemoteViews` layout using Arabic text.
3. THE Widget_Provider SHALL apply a background drawable with a gradient from `#1B5E5E` to `#5A8C8C` (Teal_Palette) and rounded corners of 16dp.
4. THE Widget_Provider SHALL apply Upcoming_Prayer_Highlight to the Next_Prayer row by setting its text color to `#FFFFFF` and font style to bold, and dimming the other four rows to 60% opacity.
5. WHEN Widget_Data_JSON is available, THE Widget_Provider SHALL display the Hijri date string in a header row above the five-prayer list.
6. WHEN Widget_Data_JSON is available, THE Widget_Provider SHALL display the Next_Prayer name and time in a dedicated banner row at the top of the widget.
7. THE Widget_Provider SHALL register a `PendingIntent` on the widget root view so that tapping the widget opens `MainActivity`.
8. THE Resizable_Android_Widget SHALL define `minResizeWidth="180dp"` and `minResizeHeight="80dp"` in its `AppWidgetProviderInfo` XML.
9. WHEN Widget_Data_JSON is absent or malformed, THE Widget_Provider SHALL display the fallback text "جاري التحميل" for all prayer time fields.

---

### Requirement 9: Android App Widget — Update Mechanism

**User Story:** As an Android user, I want the widget to update reliably when prayer times change so the displayed times are never stale.

#### Acceptance Criteria

1. WHEN the Widget_Provider receives `ACTION_APPWIDGET_UPDATE`, THE Widget_Provider SHALL read Widget_Data_JSON from Shared_Prefs_Widget and call `onUpdate` to redraw all widget instances.
2. THE Widget_Provider SHALL NOT implement any prayer-time calculation logic; it SHALL only read and display Widget_Data_JSON.
3. WHEN `ACTION_APPWIDGET_UPDATE` is received and Shared_Prefs_Widget does not contain `flutter.widget_prayer_data`, THE Widget_Provider SHALL display the fallback text "جاري التحميل" without crashing.
4. THE Widget_Provider SHALL be declared in `AndroidManifest.xml` with `<receiver>` including `<intent-filter>` for `ACTION_APPWIDGET_UPDATE` and a `<meta-data>` reference to the `AppWidgetProviderInfo` XML.

---

### Requirement 10: Backward Compatibility and Non-Regression

**User Story:** As an existing Tazkira user, I want the new widget feature to not affect the app's current functionality so that my existing prayer time notifications, Quran reader, Qibla compass, and other features continue to work correctly.

#### Acceptance Criteria

1. THE Data_Bridge SHALL be invoked only as an additive side-effect of the app's existing lifecycle and prayer-countdown logic, and SHALL NOT replace or modify any existing `PrayerTimesService` call sites.
2. THE Data_Bridge SHALL NOT modify the `SharedPreferences` keys used by existing app features (e.g., `hijri_date_offset`, notification preference keys).
3. IF the `home_widget` package or platform channel used by the Data_Bridge is unavailable (e.g., on an unsupported platform), THEN THE Data_Bridge SHALL log a warning and return without throwing an exception.
4. THE Widget_Extension target SHALL be a separate Xcode target and SHALL NOT be embedded in the Flutter engine or Runner build phases in a way that could break the existing app build.
5. THE Widget_Provider SHALL be added to `AndroidManifest.xml` as an additive `<receiver>` declaration and SHALL NOT modify any existing `<activity>`, `<service>`, or `<receiver>` entries.
6. THE Data_Bridge SHALL remain inert (no-op) on platforms other than iOS and Android (e.g., web, desktop) by using `Platform.isIOS` / `Platform.isAndroid` guards.

---

### Requirement 11: Widget Data JSON Schema — Round-Trip Integrity

**User Story:** As a developer, I want the Widget_Data_JSON format to be stable and verifiable so that serialization bugs in the Flutter side do not silently corrupt what the native widget displays.

#### Acceptance Criteria

1. THE Data_Bridge SHALL define a `WidgetPrayerData` Dart model class with all fields listed in Requirement 1, Acceptance Criterion 5.
2. THE `WidgetPrayerData` class SHALL implement `toJson()` and `fromJson(Map<String, dynamic>)` methods.
3. FOR ALL valid `WidgetPrayerData` objects, serializing to JSON then deserializing SHALL produce an object with equal field values (round-trip property).
4. THE Widget_Extension (iOS) SHALL define a matching Swift `WidgetPrayerData` struct with a `Codable` conformance that decodes the same JSON keys.
5. THE Widget_Provider (Android) SHALL parse Widget_Data_JSON using `org.json.JSONObject` and SHALL handle missing or null fields by substituting a defined default value rather than throwing an exception.
