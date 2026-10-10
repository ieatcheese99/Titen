import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titen_app/core/widgets/status_banner.dart';
import 'package:titen_app/core/widgets/bento_card.dart';
import 'package:titen_app/core/widgets/threat_simulator_bar.dart';
import 'package:titen_app/core/theme/titen_theme.dart';
import 'package:titen_app/features/dashboard/data/models/zone_status.dart';
import 'package:titen_app/features/dashboard/application/dashboard_providers.dart';

void main() {
  group('TITEN Tactical Light UI Components Tests', () {
    testWidgets('StatusBanner renders SAFE state properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: titenLightTheme(),
          home: Scaffold(
            body: StatusBanner(status: ZoneStatus.safe()),
          ),
        ),
      );

      expect(find.text('SELURUH ZONA TERVERIFIKASI AMAN'), findsOneWidget);
      expect(find.text('EVALUASI'), findsOneWidget);
    });

    testWidgets('StatusBanner renders AWAS LONGSOR state properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: titenLightTheme(),
          home: Scaffold(
            body: StatusBanner(status: ZoneStatus.awasLongsor()),
          ),
        ),
      );

      expect(find.text('🔴 AWAS LONGSOR — PERINGATAN KRITIS'), findsOneWidget);
    });

    testWidgets('BentoCard renders telemetry data and status properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: titenLightTheme(),
          home: const Scaffold(
            body: BentoCard(
              icon: Icons.water_drop,
              label: 'Soil Moisture',
              value: '42.8%',
              subtitle: 'Optimal Range',
            ),
          ),
        ),
      );

      expect(find.text('SOIL MOISTURE'), findsOneWidget);
      expect(find.text('42.8%'), findsOneWidget);
      expect(find.text('Optimal Range'), findsOneWidget);
    });

    testWidgets('ThreatSimulatorBar renders simulation pills in DEMO mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataSourceModeProvider.overrideWith((ref) => DataSourceMode.demo),
          ],
          child: MaterialApp(
            theme: titenLightTheme(),
            home: const Scaffold(
              body: ThreatSimulatorBar(),
            ),
          ),
        ),
      );

      expect(find.text('🟢 Aman'), findsOneWidget);
      expect(find.text('🟡 Waspada Longsor'), findsOneWidget);
      expect(find.text('🔴 AWAS LONGSOR'), findsOneWidget);
    });

    test('Repository streams all initial nodes and aggregates in DEMO mode', () async {
      final container = ProviderContainer(
        overrides: [
          dataSourceModeProvider.overrideWith((ref) => DataSourceMode.demo),
        ],
      );
      try {
        final nodes = await container.read(allNodesProvider.future);
        expect(nodes.length, 3);
        expect(nodes.first.name, contains('Node 01'));

        final fleet = container.read(fleetSummaryProvider);
        expect(fleet.totalRegistered, 3);
        expect(fleet.freshCount, greaterThan(0));
      } finally {
        container.dispose();
      }
    });
  });
}
