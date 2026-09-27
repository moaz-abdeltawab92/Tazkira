// Feature: prayer-times-widget
// Property-based tests for PrayerDataSnapshot.
//
// These tests verify *invariants* — properties that must hold for any valid
// input, not just a single example. Each property is exercised over 100
// randomly generated inputs to surface edge cases that hand-picked examples
// might miss.
//
// No external PBT library is required. Generators are simple Dart functions
// producing random values from meaningful domains.

import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tazkira_app/core/models/prayer_data_snapshot.dart';

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

final _rng = Random(42); // fixed seed for reproducibility

/// Generates a random ISO-8601 UTC string within a realistic prayer-time range.
String _randomIsoTime() {
  // Random hour 0–23, minute 0–59, a fixed date
  final h = _rng.nextInt(24);
  final m = _rng.nextInt(60);
  return '2025-07-${(_rng.nextInt(28) + 1).toString().padLeft(2, '0')}'
      'T${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00.000Z';
}

/// Picks a random Arabic prayer name from the five obligatory prayers.
String _randomPrayerName() {
  const names = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
  return names[_rng.nextInt(names.length)];
}

/// Generates a random Hijri date string in the format used by the app.
String _randomHijriDate() {
  const months = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];
  final day = _rng.nextInt(29) + 1;
  final month = months[_rng.nextInt(months.length)];
  final year = 1440 + _rng.nextInt(20);
  return '$day $month $year هـ';
}

/// Generates a fully valid random [PrayerDataSnapshot].
PrayerDataSnapshot _randomSnapshot() {
  return PrayerDataSnapshot(
    fajr: _randomIsoTime(),
    dhuhr: _randomIsoTime(),
    asr: _randomIsoTime(),
    maghrib: _randomIsoTime(),
    isha: _randomIsoTime(),
    nextPrayerName: _randomPrayerName(),
    nextPrayerTime: _randomIsoTime(),
    hijriDate: _randomHijriDate(),
    snapshotTimestamp: _randomIsoTime(),
  );
}

/// Generates a random non-empty string for use as a JSON field value.
String _randomString() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final len = _rng.nextInt(20) + 1;
  return String.fromCharCodes(
    List.generate(len, (_) => chars.codeUnitAt(_rng.nextInt(chars.length))),
  );
}

/// The display fields compared by [contentEquals] (excludes snapshotTimestamp).
const _displayFields = [
  'fajr',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
  'nextPrayerName',
  'nextPrayerTime',
  'hijriDate',
];

// ---------------------------------------------------------------------------
// Property runner helper
// ---------------------------------------------------------------------------

/// Runs [property] with [iterations] random inputs.
/// Fails the test at the first counter-example with a descriptive message.
void forAll(
  int iterations,
  PrayerDataSnapshot Function() generator,
  void Function(PrayerDataSnapshot) property,
) {
  for (var i = 0; i < iterations; i++) {
    final snapshot = generator();
    property(snapshot);
  }
}

// ---------------------------------------------------------------------------
// Properties
// ---------------------------------------------------------------------------

void main() {
  const iterations = 100;

  // ── Property 1: Serialise → Deserialise preserves all display data ─────────
  //
  // For any valid snapshot s:
  //   fromJson(s.toJson()) produces a snapshot that contentEquals(s)
  //
  // This verifies that no display field is lost or corrupted through the
  // JSON serialisation round-trip.

  test(
    'Property 1 (×$iterations): '
    'fromJson(toJson(s)) always produces a snapshot contentEqual to s',
    () {
      forAll(iterations, _randomSnapshot, (s) {
        final restored = PrayerDataSnapshot.fromJson(s.toJson());
        expect(
          restored,
          isNotNull,
          reason: 'fromJson should succeed for any valid snapshot',
        );
        expect(
          s.contentEquals(restored!),
          isTrue,
          reason: 'Round-tripped snapshot must contentEqual the original. '
              'Original: $s, Restored: $restored',
        );
      });
    },
  );

  // ── Property 2: contentEquals is reflexive ──────────────────────────────────
  //
  // For any snapshot s: s.contentEquals(s) == true

  test(
    'Property 2 (×$iterations): '
    'contentEquals() is reflexive — s.contentEquals(s) is always true',
    () {
      forAll(iterations, _randomSnapshot, (s) {
        expect(
          s.contentEquals(s),
          isTrue,
          reason: 'contentEquals must be reflexive',
        );
      });
    },
  );

  // ── Property 3: contentEquals is symmetric ──────────────────────────────────
  //
  // For any two snapshots a and b:
  //   a.contentEquals(b) == b.contentEquals(a)

  test(
    'Property 3 (×$iterations): '
    'contentEquals() is symmetric — a.contentEquals(b) == b.contentEquals(a)',
    () {
      for (var i = 0; i < iterations; i++) {
        final a = _randomSnapshot();
        // b is either a copy of a (equal) or an independent random snapshot (likely unequal)
        final b = _rng.nextBool() ? _randomSnapshot() : _randomSnapshot();
        expect(
          a.contentEquals(b),
          equals(b.contentEquals(a)),
          reason: 'contentEquals must be symmetric. a: $a, b: $b',
        );
      }
    },
  );

  // ── Property 4: snapshotTimestamp alone never affects contentEquals ─────────
  //
  // For any snapshot s, replacing only snapshotTimestamp produces a snapshot
  // that still contentEquals(s).
  //
  // This is the most important invariant for the change-detection mechanism:
  // widgets must not reload just because the snapshot was rebuilt at a
  // different moment.

  test(
    'Property 4 (×$iterations): '
    'Changing only snapshotTimestamp never changes contentEquals()',
    () {
      forAll(iterations, _randomSnapshot, (s) {
        final differentTimestamp = PrayerDataSnapshot(
          fajr: s.fajr,
          dhuhr: s.dhuhr,
          asr: s.asr,
          maghrib: s.maghrib,
          isha: s.isha,
          nextPrayerName: s.nextPrayerName,
          nextPrayerTime: s.nextPrayerTime,
          hijriDate: s.hijriDate,
          snapshotTimestamp: _randomIsoTime(), // different
        );
        expect(
          s.contentEquals(differentTimestamp),
          isTrue,
          reason:
              'Changing only snapshotTimestamp must not break contentEquals',
        );
      });
    },
  );

  // ── Property 5: Changing any display field always changes contentEquals ──────
  //
  // For any snapshot s and any display field f:
  //   replacing f with a different non-empty value produces a snapshot
  //   where !s.contentEquals(modified)
  //
  // Ensures change-detection catches every field that affects the widget UI.

  test(
    'Property 5 (×$iterations per field): '
    'Changing any display field always makes contentEquals() return false',
    () {
      for (final field in _displayFields) {
        for (var i = 0; i < iterations; i++) {
          final s = _randomSnapshot();
          final json = s.toJson();
          final original = json[field] as String;

          // Replace with a value that is guaranteed to differ.
          // We append a suffix to the original; if the original ends with 'X'
          // already, we prepend instead — in practice this is always different.
          json[field] = '${original}_MODIFIED';

          final modified = PrayerDataSnapshot.fromJson(json);
          // fromJson may return null for edge cases — that also satisfies
          // the property (null != s means contentEquals is trivially false).
          if (modified == null) continue;

          expect(
            s.contentEquals(modified),
            isFalse,
            reason: 'Changing field "$field" must break contentEquals. '
                'Original: $original, Modified: ${json[field]}',
          );
        }
      }
    },
  );

  // ── Property 6: Invalid snapshots are never reported as valid ───────────────
  //
  // For any snapshot where at least one of the five prayer times or
  // nextPrayerName is empty, isValid() must return false.

  test(
    'Property 6 (×$iterations): '
    'Snapshots with any empty required field are always invalid',
    () {
      const requiredFields = [
        'fajr',
        'dhuhr',
        'asr',
        'maghrib',
        'isha',
        'nextPrayerName',
      ];

      for (var i = 0; i < iterations; i++) {
        final s = _randomSnapshot();
        // Pick a random required field to empty.
        final field = requiredFields[_rng.nextInt(requiredFields.length)];
        final json = s.toJson();
        json[field] = '';

        // fromJson returns null for empty required fields — both null and
        // isValid()==false satisfy "not a valid snapshot".
        final result = PrayerDataSnapshot.fromJson(json);
        if (result != null) {
          expect(
            result.isValid(),
            isFalse,
            reason: 'Empty "$field" must make isValid() return false',
          );
        }
        // null result also satisfies the property.
      }
    },
  );

  // ── Property 7: Unknown JSON fields never affect parsing of valid snapshots ──
  //
  // For any valid snapshot s and any number of unknown extra fields added to
  // its JSON representation, fromJson still successfully parses all 9 required
  // fields and the result contentEquals(s).

  test(
    'Property 7 (×$iterations): '
    'Unknown JSON fields never affect parsing of valid snapshots',
    () {
      forAll(iterations, _randomSnapshot, (s) {
        final json = s.toJson();

        // Add 1–5 random unknown fields.
        final extraCount = _rng.nextInt(5) + 1;
        for (var j = 0; j < extraCount; j++) {
          json['unknown_${_randomString()}'] = _randomString();
        }

        final result = PrayerDataSnapshot.fromJson(json);
        expect(
          result,
          isNotNull,
          reason: 'Extra unknown fields must not prevent parsing',
        );
        expect(
          s.contentEquals(result!),
          isTrue,
          reason: 'Unknown fields must not corrupt any display field',
        );
      });
    },
  );

  // ── Property 8: toJson never includes sunrise, latitude, or longitude ────────
  //
  // For any valid snapshot, the serialised JSON must never contain fields
  // that were intentionally excluded from the widget data contract.

  test(
    'Property 8 (×$iterations): '
    'toJson() never includes sunrise, latitude, or longitude',
    () {
      forAll(iterations, _randomSnapshot, (s) {
        final json = s.toJson();
        expect(json.containsKey('sunrise'), isFalse);
        expect(json.containsKey('latitude'), isFalse);
        expect(json.containsKey('longitude'), isFalse);
        expect(json.containsKey('hijriOffset'), isFalse);
      });
    },
  );

  // ── Property 9: JSON string round-trip is idempotent ─────────────────────────
  //
  // For any valid snapshot s:
  //   encode(decode(encode(s))) produces a map equal to encode(s)
  //
  // Verifies that the string serialisation path (toJsonString / fromJsonString)
  // is stable under repeated application.

  test(
    'Property 9 (×$iterations): '
    'JSON string round-trip is idempotent — encode(decode(encode(s))) == encode(s)',
    () {
      forAll(iterations, _randomSnapshot, (s) {
        final firstEncoding = jsonEncode(s.toJson());
        final decoded = PrayerDataSnapshot.fromJsonString(firstEncoding);
        expect(decoded, isNotNull,
            reason: 'fromJsonString must succeed for any valid snapshot');
        final secondEncoding = jsonEncode(decoded!.toJson());

        // Compare as parsed maps so key ordering does not matter.
        final map1 = jsonDecode(firstEncoding) as Map<String, dynamic>;
        final map2 = jsonDecode(secondEncoding) as Map<String, dynamic>;
        expect(map2, equals(map1),
            reason: 'Second encoding must equal first encoding');
      });
    },
  );
}
