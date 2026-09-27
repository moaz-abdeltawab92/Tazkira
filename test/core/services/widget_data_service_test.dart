import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tazkira_app/core/models/prayer_data_snapshot.dart';
import 'package:tazkira_app/core/services/widget_data_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Channel mock setup
  // ---------------------------------------------------------------------------

  // Records every method call made on the widget channel.
  final List<MethodCall> log = [];

  // Handler behaviour controlled per test.
  Future<dynamic> Function(MethodCall)? _handler;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    log.clear();
    _handler = (call) async => true; // default: succeed silently

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.moaz.tazkira/widget_channel'),
      (MethodCall call) async {
        log.add(call);
        return _handler?.call(call);
      },
    );

    // Reset singleton state so each test starts from a clean slate.
    WidgetDataService.instance.resetForTesting();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.moaz.tazkira/widget_channel'),
      null,
    );
  });

  // ---------------------------------------------------------------------------
  // Shared fixtures
  // ---------------------------------------------------------------------------

  PrayerDataSnapshot makeSnapshot({String nextPrayerName = 'المغرب'}) {
    return PrayerDataSnapshot(
      fajr: '2025-07-14T01:43:00.000Z',
      dhuhr: '2025-07-14T10:04:00.000Z',
      asr: '2025-07-14T13:38:00.000Z',
      maghrib: '2025-07-14T16:55:00.000Z',
      isha: '2025-07-14T18:29:00.000Z',
      nextPrayerName: nextPrayerName,
      nextPrayerTime: '2025-07-14T16:55:00.000Z',
      hijriDate: '18 محرم 1447 هـ',
      snapshotTimestamp: '2025-07-14T15:30:00.000Z',
    );
  }

  // ---------------------------------------------------------------------------
  // Change detection — no reload when content unchanged
  // ---------------------------------------------------------------------------

  group('Change detection — no reload when content unchanged', () {
    test(
        'publishSnapshot() does not call reloadWidgets when snapshot content is identical',
        () async {
      final snapshot = makeSnapshot();

      // First publish — should write + reload.
      await WidgetDataService.instance.publishSnapshot(snapshot);
      final firstCallCount = log.length;
      expect(firstCallCount, greaterThan(0));

      log.clear();

      // Second publish with same content (different timestamp is ignored).
      final sameContent = PrayerDataSnapshot(
        fajr: snapshot.fajr,
        dhuhr: snapshot.dhuhr,
        asr: snapshot.asr,
        maghrib: snapshot.maghrib,
        isha: snapshot.isha,
        nextPrayerName: snapshot.nextPrayerName,
        nextPrayerTime: snapshot.nextPrayerTime,
        hijriDate: snapshot.hijriDate,
        snapshotTimestamp: '2025-07-14T16:00:00.000Z', // different timestamp
      );
      await WidgetDataService.instance.publishSnapshot(sameContent);

      // No channel calls should have been made.
      expect(log, isEmpty,
          reason: 'Should not write or reload when content is unchanged');
    });

    test('publishSnapshot() skips write for invalid snapshot', () async {
      const invalid = PrayerDataSnapshot(
        fajr: '',
        dhuhr: '',
        asr: '',
        maghrib: '',
        isha: '',
        nextPrayerName: '',
        nextPrayerTime: '2025-07-14T16:55:00.000Z',
        hijriDate: '18 محرم 1447 هـ',
        snapshotTimestamp: '2025-07-14T15:30:00.000Z',
      );
      await WidgetDataService.instance.publishSnapshot(invalid);
      expect(log, isEmpty,
          reason: 'Invalid snapshot should not trigger any channel call');
    });
  });

  // ---------------------------------------------------------------------------
  // Reload triggered exactly once on content change
  // ---------------------------------------------------------------------------

  group('Reload triggered exactly once on content change', () {
    test(
        'publishSnapshot() calls reloadWidgets exactly once when content changes',
        () async {
      final snapshot = makeSnapshot();
      await WidgetDataService.instance.publishSnapshot(snapshot);

      final reloadCalls =
          log.where((c) => c.method == 'reloadWidgets').toList();
      expect(reloadCalls.length, equals(1),
          reason: 'reloadWidgets should be called exactly once per publish');
    });

    test(
        'publishSnapshot() calls writeWidgetData exactly once when content changes',
        () async {
      final snapshot = makeSnapshot();
      await WidgetDataService.instance.publishSnapshot(snapshot);

      final writeCalls =
          log.where((c) => c.method == 'writeWidgetData').toList();
      expect(writeCalls.length, equals(1),
          reason: 'writeWidgetData should be called exactly once per publish');
    });

    test('second publish with changed nextPrayerName triggers reload',
        () async {
      await WidgetDataService.instance
          .publishSnapshot(makeSnapshot(nextPrayerName: 'المغرب'));
      log.clear();

      await WidgetDataService.instance
          .publishSnapshot(makeSnapshot(nextPrayerName: 'العشاء'));

      final reloadCalls =
          log.where((c) => c.method == 'reloadWidgets').toList();
      expect(reloadCalls.length, equals(1),
          reason: 'Should reload once when nextPrayerName changes');
    });

    test('identical snapshot published twice — total reload count is 1',
        () async {
      final snapshot = makeSnapshot();
      await WidgetDataService.instance.publishSnapshot(snapshot);
      await WidgetDataService.instance
          .publishSnapshot(snapshot); // same content

      final reloadCalls =
          log.where((c) => c.method == 'reloadWidgets').toList();
      expect(reloadCalls.length, equals(1),
          reason:
              'reloadWidgets should only be called once for two identical publishes');
    });
  });

  // ---------------------------------------------------------------------------
  // MissingPluginException — graceful handling
  // ---------------------------------------------------------------------------

  group('MissingPluginException — graceful handling', () {
    test(
        'publishSnapshot() does not throw when MissingPluginException is raised',
        () async {
      // Remove the mock handler — this simulates an unregistered channel,
      // which causes Flutter to throw MissingPluginException.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.moaz.tazkira/widget_channel'),
        null,
      );

      final snapshot = makeSnapshot();
      // Must not throw.
      await expectLater(
        WidgetDataService.instance.publishSnapshot(snapshot),
        completes,
      );
    });

    test(
        'isWidgetInstalled() returns false when MissingPluginException is raised',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.moaz.tazkira/widget_channel'),
        null,
      );

      final result = await WidgetDataService.instance.isWidgetInstalled();
      expect(result, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // PlatformException — logged, never crashes
  // ---------------------------------------------------------------------------

  group('PlatformException — logged, never crashes', () {
    test(
        'publishSnapshot() does not throw when writeWidgetData raises PlatformException',
        () async {
      _handler = (call) async {
        if (call.method == 'writeWidgetData') {
          throw PlatformException(code: 'WRITE_ERROR', message: 'disk full');
        }
        return null;
      };

      final snapshot = makeSnapshot();
      // Must not throw — error is logged, method returns normally.
      await expectLater(
        WidgetDataService.instance.publishSnapshot(snapshot),
        completes,
      );
    });

    test(
        'publishSnapshot() does not throw when reloadWidgets raises PlatformException',
        () async {
      _handler = (call) async {
        if (call.method == 'reloadWidgets') {
          throw PlatformException(code: 'RELOAD_ERROR', message: 'widget gone');
        }
        return true; // writeWidgetData succeeds
      };

      final snapshot = makeSnapshot();
      await expectLater(
        WidgetDataService.instance.publishSnapshot(snapshot),
        completes,
      );
    });

    test(
        'publishSnapshot() does not throw when an unexpected Exception is raised',
        () async {
      _handler = (call) async {
        throw Exception('unexpected network error');
      };

      final snapshot = makeSnapshot();
      await expectLater(
        WidgetDataService.instance.publishSnapshot(snapshot),
        completes,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // writeWidgetData payload
  // ---------------------------------------------------------------------------

  group('writeWidgetData payload', () {
    test('passes snapshot as a Map argument to the channel', () async {
      final snapshot = makeSnapshot();
      await WidgetDataService.instance.publishSnapshot(snapshot);

      final writeCall = log.firstWhere((c) => c.method == 'writeWidgetData');
      final args = writeCall.arguments as Map;

      expect(args['fajr'], snapshot.fajr);
      expect(args['nextPrayerName'], snapshot.nextPrayerName);
      expect(args['hijriDate'], snapshot.hijriDate);
      expect(args.containsKey('sunrise'), isFalse);
      expect(args.containsKey('latitude'), isFalse);
    });
  });
}
