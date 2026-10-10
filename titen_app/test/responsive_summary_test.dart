import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titen_app/core/theme/titen_theme.dart';
import 'package:titen_app/core/widgets/fleet_summary_card.dart';
import 'package:titen_app/core/widgets/gateway_health_card.dart';
import 'package:titen_app/core/widgets/node_row.dart';
import 'package:titen_app/core/widgets/custom_top_bar.dart';
import 'package:titen_app/features/dashboard/application/dashboard_providers.dart';
import 'package:titen_app/features/dashboard/data/models/gateway_health.dart';
import 'package:titen_app/features/dashboard/data/models/sensor_node.dart';

void main() {
  for (final width in [320.0, 360.0, 640.0, 1440.0]) {
    testWidgets('Node summary remains readable at ${width.toInt()}dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final node = SensorNode(
        nodeId: 1,
        name: 'Node lereng dengan nama lokasi yang panjang',
        receivedAt: DateTime.now(),
        lastStatusLevel: 3,
        lastHazardType: 1,
        batteryPct: 75,
        loraRssi: -120,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allNodesProvider.overrideWith((ref) => Stream.value([node])),
            alertsProvider.overrideWith((ref) => Stream.value([])),
            gatewayHealthProvider.overrideWith(
              (ref) => Stream.value(GatewayHealth.unknown()),
            ),
          ],
          child: MaterialApp(
            theme: titenLightTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(
              appBar: const CustomTopBar(),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const FleetSummaryCard(),
                    const SizedBox(height: 16),
                    const GatewayHealthCard(),
                    const SizedBox(height: 16),
                    NodeRow(node: node, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Data Terbaru (Fresh)'), findsOneWidget);
      expect(find.text('LoRa Receiver'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('-120 dBm'), findsOneWidget);
      expect(find.text('433 MHz'), findsNothing);
    });
  }
}
