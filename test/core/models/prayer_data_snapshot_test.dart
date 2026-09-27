import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tazkira_app/core/models/prayer_data_snapshot.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared test fixture
  // ---------------------------------------------------------------------------

  const validSnapshot = PrayerDataSnapshot(
    fajr: '2025-07-14T01:43:00.000Z',
    dhuhr: '2025-07-14T10:04:00.000Z',
    asr: '2025-07-14T13:38:00.000Z',
    maghrib: '2025-07-14T16:55:00.000Z',
    isha: '2025-07-14T18:29:00.000Z',
    nextPrayerName: 'المغرب',
    nextPrayerTime: '2025-07-14T16:55:00.000Z',
    hijriDate: '18 محرم 1447 هـ',
    snapshotTimestamp: '2025-07-14T15:30:00.000Z',
  );

  // ---------------------------------------------------------------------------
  // toJson() — excluded fields
  // ---------------------------------------------------------------------------

  group('toJson() — excluded fields', () {
    test('does not contain sunrise key', () {
      final json = validSnapshot.toJson();
      expect(json.containsKey('sunrise'), isFalse);
    });

    test('does not contain latitude key', () {
      final json = validSnapshot.toJson();
      expect(json.containsKey('latitude'), isFalse);
    });

    test('does not contain longitude key', () {
      final json = validSnapshot.toJson();
      expect(json.containsKey('longitude'), isFalse);
    });

    test('does not contain hijriOffset key', () {
      final json = validSnapshot.toJson();
      expect(json.containsKey('hijriOffset'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // toJson() — required fields present and non-null
  // ---------------------------------------------------------------------------

  group('toJson() — required fields', () {
    test('contains all 9 required keys', () {
      final json = validSnapshot.toJson();
      const requiredKeys = [
        'fajr',
        'dhuhr',
        'asr',
        'maghrib',
        'isha',
        'nextPrayerName',
        'nextPrayerTime',
        'hijriDate',
        'snapshotTimestamp',
      ];
      for (final key in requiredKeys) {
        expect(json.containsKey(key), isTrue, reason: 'Missing key: $key');
        expect(json[key], isNotNull, reason: 'Null value for key: $key');
      }
    });

    test('serialises prayer times as non-empty strings', () {
      final json = validSnapshot.toJson();
      for (final key in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        expect((json[key] as String).isNotEmpty, isTrue,
            reason: '$key should be non-empty');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson() — round-trip and unknown fields
  // ---------------------------------------------------------------------------

  group('fromJson()', () {
    test('round-trips a valid snapshot without data loss', () {
      final json = validSnapshot.toJson();
      final restored = PrayerDataSnapshot.fromJson(json);
      expect(restored, isNotNull);
      expect(restored!.fajr, validSnapshot.fajr);
      expect(restored.dhuhr, validSnapshot.dhuhr);
      expect(restored.asr, validSnapshot.asr);
      expect(restored.maghrib, validSnapshot.maghrib);
      expect(restored.isha, validSnapshot.isha);
      expect(restored.nextPrayerName, validSnapshot.nextPrayerName);
      expect(restored.nextPrayerTime, validSnapshot.nextPrayerTime);
      expect(restored.hijriDate, validSnapshot.hijriDate);
      expect(restored.snapshotTimestamp, validSnapshot.snapshotTimestamp);
    });

    test('ignores unknown extra keys without throwing', () {
      final json = validSnapshot.toJson();
      json['unknownField'] = 'unexpected';
      json['anotherExtra'] = 42;
      expect(() => PrayerDataSnapshot.fromJson(json), returnsNormally);
      final result = PrayerDataSnapshot.fromJson(json);
      expect(result, isNotNull);
    });

    test('returns null when a required field is missing', () {
      for (final key in [
        'fajr',
        'dhuhr',
        'asr',
        'maghrib',
        'isha',
        'nextPrayerName',
        'nextPrayerTime'
      ]) {
        final json = validSnapshot.toJson();
        json.remove(key);
        expect(PrayerDataSnapshot.fromJson(json), isNull,
            reason: 'Should return null when $key is missing');
      }
    });

    test('returns null for empty map', () {
      expect(PrayerDataSnapshot.fromJson({}), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJsonString()
  // ---------------------------------------------------------------------------

  group('fromJsonString()', () {
    test('parses a valid JSON string', () {
      final jsonString = jsonEncode(validSnapshot.toJson());
      expect(PrayerDataSnapshot.fromJsonString(jsonString), isNotNull);
    });

    test('returns null for malformed JSON', () {
      expect(PrayerDataSnapshot.fromJsonString('{not valid json'), isNull);
    });

    test('returns null for empty string', () {
      expect(PrayerDataSnapshot.fromJsonString(''), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // contentEquals()
  // ---------------------------------------------------------------------------

  group('contentEquals()', () {
    test('returns true for two identical snapshots', () {
      const copy = PrayerDataSnapshot(
        fajr: '2025-07-14T01:43:00.000Z',
        dhuhr: '2025-07-14T10:04:00.000Z',
        asr: '2025-07-14T13:38:00.000Z',
        maghrib: '2025-07-14T16:55:00.000Z',
        isha: '2025-07-14T18:29:00.000Z',
        nextPrayerName: 'المغرب',
        nextPrayerTime: '2025-07-14T16:55:00.000Z',
        hijriDate: '18 محرم 1447 هـ',
        snapshotTimestamp: '2025-07-14T15:30:00.000Z',
      );
      expect(validSnapshot.contentEquals(copy), isTrue);
    });

    test('returns true when only snapshotTimestamp differs', () {
      // snapshotTimestamp is intentionally excluded from contentEquals
      const differentTimestamp = PrayerDataSnapshot(
        fajr: '2025-07-14T01:43:00.000Z',
        dhuhr: '2025-07-14T10:04:00.000Z',
        asr: '2025-07-14T13:38:00.000Z',
        maghrib: '2025-07-14T16:55:00.000Z',
        isha: '2025-07-14T18:29:00.000Z',
        nextPrayerName: 'المغرب',
        nextPrayerTime: '2025-07-14T16:55:00.000Z',
        hijriDate: '18 محرم 1447 هـ',
        snapshotTimestamp: '2025-07-14T16:00:00.000Z', // different
      );
      expect(validSnapshot.contentEquals(differentTimestamp), isTrue);
    });

    test('returns false when nextPrayerName differs', () {
      final other = PrayerDataSnapshot(
        fajr: validSnapshot.fajr,
        dhuhr: validSnapshot.dhuhr,
        asr: validSnapshot.asr,
        maghrib: validSnapshot.maghrib,
        isha: validSnapshot.isha,
        nextPrayerName: 'العشاء', // different
        nextPrayerTime: validSnapshot.nextPrayerTime,
        hijriDate: validSnapshot.hijriDate,
        snapshotTimestamp: validSnapshot.snapshotTimestamp,
      );
      expect(validSnapshot.contentEquals(other), isFalse);
    });

    test('returns false when any prayer time differs', () {
      for (final field in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        final json = validSnapshot.toJson();
        json[field] = '2025-07-14T00:00:00.000Z'; // different time
        final other = PrayerDataSnapshot.fromJson(json)!;
        expect(validSnapshot.contentEquals(other), isFalse,
            reason: 'Should detect change in $field');
      }
    });

    test('returns false when hijriDate differs', () {
      final other = PrayerDataSnapshot(
        fajr: validSnapshot.fajr,
        dhuhr: validSnapshot.dhuhr,
        asr: validSnapshot.asr,
        maghrib: validSnapshot.maghrib,
        isha: validSnapshot.isha,
        nextPrayerName: validSnapshot.nextPrayerName,
        nextPrayerTime: validSnapshot.nextPrayerTime,
        hijriDate: '19 محرم 1447 هـ', // different
        snapshotTimestamp: validSnapshot.snapshotTimestamp,
      );
      expect(validSnapshot.contentEquals(other), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // isValid()
  // ---------------------------------------------------------------------------

  group('isValid()', () {
    test('returns true for a fully populated snapshot', () {
      expect(validSnapshot.isValid(), isTrue);
    });

    test('returns false when any prayer time field is empty', () {
      for (final field in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        final json = validSnapshot.toJson();
        json[field] = '';
        final snapshot = PrayerDataSnapshot.fromJson(json);
        // fromJson returns null for empty required fields — both behaviors
        // (null or isValid()==false) satisfy the contract.
        if (snapshot != null) {
          expect(snapshot.isValid(), isFalse,
              reason: '$field empty should be invalid');
        }
      }
    });

    test('returns false when nextPrayerName is empty', () {
      const invalid = PrayerDataSnapshot(
        fajr: '2025-07-14T01:43:00.000Z',
        dhuhr: '2025-07-14T10:04:00.000Z',
        asr: '2025-07-14T13:38:00.000Z',
        maghrib: '2025-07-14T16:55:00.000Z',
        isha: '2025-07-14T18:29:00.000Z',
        nextPrayerName: '', // empty
        nextPrayerTime: '2025-07-14T16:55:00.000Z',
        hijriDate: '18 محرم 1447 هـ',
        snapshotTimestamp: '2025-07-14T15:30:00.000Z',
      );
      expect(invalid.isValid(), isFalse);
    });

    test('PrayerDataSnapshot.empty() is always invalid', () {
      expect(PrayerDataSnapshot.empty().isValid(), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // JSON round-trip string serialisation
  // ---------------------------------------------------------------------------

  group('JSON round-trip — string serialisation', () {
    test('re-serialising a decoded snapshot produces equivalent JSON', () {
      final original = jsonEncode(validSnapshot.toJson());
      final decoded = PrayerDataSnapshot.fromJsonString(original)!;
      final reEncoded = jsonEncode(decoded.toJson());
      // Compare parsed maps for key/value equality (key order may differ)
      final originalMap = jsonDecode(original) as Map<String, dynamic>;
      final reEncodedMap = jsonDecode(reEncoded) as Map<String, dynamic>;
      expect(reEncodedMap, equals(originalMap));
    });
  });
}
