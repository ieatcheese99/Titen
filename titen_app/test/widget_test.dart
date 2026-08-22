import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titen_app/core/widgets/status_banner.dart';
import 'package:titen_app/core/widgets/bento_card.dart';
import 'package:titen_app/core/widgets/threat_simulator_bar.dart';
import 'package:titen_app/features/dashboard/data/models/zone_status.dart';
import 'package:titen_app/features/dashboard/application/dashboard_providers.dart';

void main() {
  group('TITEN Tactical Light UI Components Tests', () {
    testWidgets('StatusBanner renders SAFE state properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner(status: ZoneStatus.safe()),
          ),
        ),
      );

      expect(find.text('ALL ZONES SAFE'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('StatusBanner renders AWAS LONGSOR state properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBanner(status: ZoneStatus.awasLongsor()),
          ),
        ),
      );

      expect(find.text('🔴 AWAS LONGSOR — EVAKUASI SEGERA'), findsOneWidget);
      expect(find.byIcon(Icons.gpp_bad_rounded), findsOneWidget);
    });

    testWidgets('BentoCard renders telemetry data and status properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
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

    testWidgets('ThreatSimulatorBar renders simulation pills', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThreatSimulatorBar(),
            ),
          ),
        ),
      );

      expect(find.text('🟢 Aman'), findsOneWidget);
      expect(find.text('🚨 AWAS LONGSOR'), findsOneWidget);
      expect(find.text('🔥 AWAS KARHUTLA'), findsOneWidget);
    });

    test('Repository streams all initial nodes and aggregates', () async {
      final container = ProviderContainer();
      try {
        final nodes = await container.read(allNodesProvider.future);
        expect(nodes.length, 4);
        expect(nodes.first.name, contains('Node 01'));

        final aggregates = container.read(aggregateTelemetryProvider);
        expect(aggregates.totalNodes, 4);
        expect(aggregates.avgSoilMoisture, greaterThan(0));
        expect(aggregates.avgAirTemp, greaterThan(0));
      } finally {
        container.dispose();
      }
    });
  });
}
