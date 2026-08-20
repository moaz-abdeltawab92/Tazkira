import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Reproduces the "Duplicate GlobalKey detected in widget tree" pattern from
// home_body.dart: a top-level GlobalKey on a child whose ancestor's ValueKey
// changes between frames (Homepage._refreshTrigger → HomeBody key swap).

final _sharedKey = GlobalKey();

Widget _homeBody(int refreshValue) {
  return SizedBox(
    key: ValueKey(refreshValue), // HomeBody(key: ValueKey(refreshValue))
    child: Column(
      // Same parent shape as home_body.dart: default alignments.
      children: [
        Text('prayer card', key: _sharedKey), // PrayerTimesCardsWidget(key: _prayerTimesKey)
      ],
    ),
  );
}

void main() {
  testWidgets('swapping ancestor ValueKey with shared GlobalKey child', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: const Scaffold(body: SizedBox())), // placeholder frame
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: _homeBody(0))),
    );
    await tester.pump();

    // Simulates _refreshTrigger.value++ (PodcastsPage returns true).
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: _homeBody(1))),
    );

    // Finalize the frame — the duplicate-key assertion fires during
    // BuildOwner.finalizeTree if the pattern is broken.
    await tester.pump();

    expect(find.text('prayer card'), findsOneWidget);
  });

  testWidgets('FutureBuilder season wrap/unwrap with shared GlobalKey child', (
    tester,
  ) async {
    Widget withSeason(String? season) {
      Widget body = _homeBody(0);
      if (season != null) {
        body = Directionality(
          key: UniqueKey(), // forces a fresh subtree like SeasonalDecor insertion
          textDirection: TextDirection.ltr,
          child: body,
        );
      }
      return MaterialApp(home: Scaffold(body: body));
    }

    await tester.pumpWidget(withSeason(null));
    await tester.pump();
    await tester.pumpWidget(withSeason('ramadan'));
    await tester.pump();
    await tester.pumpWidget(withSeason(null));
    await tester.pump();

    expect(find.text('prayer card'), findsOneWidget);
  });
}
