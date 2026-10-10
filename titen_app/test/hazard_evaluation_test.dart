import 'package:flutter_test/flutter_test.dart';
import 'package:titen_app/features/dashboard/data/models/telemetry_data.dart';
import 'package:titen_app/features/dashboard/data/models/sensor_node.dart';
import 'package:titen_app/features/dashboard/data/models/zone_status.dart';

void main() {
  group('TITEN Dual Hazard Evaluation Tests (FR-1.4)', () {
    test('Should evaluate Landslide hazard when tilt > 5.0 deg and soil > 80%', () {
      final normalTelemetry = TelemetryData(
        nodeId: 1,
        batteryPct: 95,
        tiltDeg: 1.2,
        soilMoisturePct: 40.0,
        airTempC: 25.0,
        airHumidityPct: 60.0,
        hazardType: 0,
        statusLevel: 0,
        timestamp: DateTime.now(),
      );
      expect(normalTelemetry.isLandslideHazard, isFalse);
      expect(normalTelemetry.isKarhutlaHazard, isFalse);

      final landslideTelemetry = TelemetryData(
        nodeId: 1,
        batteryPct: 90,
        tiltDeg: 7.2,
        soilMoisturePct: 85.0,
        airTempC: 24.0,
        airHumidityPct: 70.0,
        hazardType: 1,
        statusLevel: 3,
        timestamp: DateTime.now(),
      );
      expect(landslideTelemetry.isLandslideHazard, isTrue);
      expect(landslideTelemetry.isKarhutlaHazard, isFalse);
    });

    test('Should evaluate Karhutla hazard when air temp > 45C and humidity < 25%', () {
      final karhutlaTelemetry = TelemetryData(
        nodeId: 3,
        batteryPct: 88,
        tiltDeg: 0.5,
        soilMoisturePct: 30.0,
        airTempC: 48.5,
        airHumidityPct: 18.0,
        hazardType: 2,
        statusLevel: 3,
        timestamp: DateTime.now(),
      );
      expect(karhutlaTelemetry.isKarhutlaHazard, isTrue);
      expect(karhutlaTelemetry.isLandslideHazard, isFalse);
    });

    test('SensorNode should format status and check online correctly', () {
      final node = SensorNode(
        nodeId: 1,
        name: 'Node 01 - Tebing Curam',
        latitude: -6.9125,
        longitude: 107.6045,
        nodeType: 'landslide',
        lastStatusLevel: 3,
        lastHazardType: 1,
        batteryPct: 90,
        loraRssi: -75,
        loraSnr: 9.0,
        lastSeen: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      expect(node.statusText, 'AWAS LONGSOR');
      expect(node.hazardTypeText, 'Tanah Longsor');
      expect(node.isOnline, isTrue);
      expect(node.getFreshness(), FreshnessStatus.fresh);
    });

    test('ZoneStatus factory should return appropriate levels and colors', () {
      final safe = ZoneStatus.safe();
      expect(safe.level, 0);
      expect(safe.isSafe, isTrue);

      final awasLongsor = ZoneStatus.awasLongsor();
      expect(awasLongsor.level, 3);
      expect(awasLongsor.hazardType, 1);
      expect(awasLongsor.isDanger, isTrue);

      final awasKarhutla = ZoneStatus.awasKarhutla();
      expect(awasKarhutla.level, 3);
      expect(awasKarhutla.hazardType, 2);
      expect(awasKarhutla.isDanger, isTrue);

      final unknown = ZoneStatus.unknown();
      expect(unknown.level, -1);
      expect(unknown.isUnknown, isTrue);
    });
  });
}
