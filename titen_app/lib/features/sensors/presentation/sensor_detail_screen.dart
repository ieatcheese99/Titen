import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/hazard_constants.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/telemetry_tile.dart';
import '../../../core/widgets/sparkline_widget.dart';
import '../../../core/widgets/cache_status_footer.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../emergency/presentation/widgets/relay_action_sheet.dart';

/// Sensor Detail Screen conforming to 03_APP_FLUTTER_SPEC.md §4.3
class SensorDetailScreen extends ConsumerWidget {
  final int nodeId;

  const SensorDetailScreen({super.key, required this.nodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.titenTokens;
    final nodeAsync = ref.watch(singleNodeProvider(nodeId));
    final repo = ref.watch(nodeRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Telemetri Node ${nodeId.toString().padLeft(2, '0')}',
          style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 18),
        ),
      ),
      body: nodeAsync.when(
        data: (node) {
          if (node == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_outlined, size: 48, color: tokens.textMetadata),
                    const SizedBox(height: 12),
                    Text(
                      'Node $nodeId tidak ditemukan pada registry.',
                      style: TitenTypography.body(color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          final tele = node.lastTelemetry;
          final freshness = node.getFreshness();
          final receivedStr = node.receivedAt != null
              ? DateFormat('dd MMM yyyy, HH:mm:ss').format(node.receivedAt!)
              : (node.lastSeen != null ? DateFormat('HH:mm:ss').format(node.lastSeen!) : '—');

          final locationStr = (node.latitude != null && node.longitude != null)
              ? '${node.latitude!.toStringAsFixed(4)}, ${node.longitude!.toStringAsFixed(4)}'
              : 'Lokasi belum diatur di registry';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. M09 NodeIdentity Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.surfacePanel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.borderSubtle, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  node.name,
                                  style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Key: ${node.nodeKey} • Tipe: ${node.nodeType ?? "Geologis"}',
                                  style: TitenTypography.technical(color: tokens.textMetadata).copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              StatusBadge(statusLevel: node.lastStatusLevel, hazardType: node.lastHazardType),
                              const SizedBox(width: 4),
                              StatusBadge(freshness: freshness),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 13, color: tokens.textMetadata),
                              const SizedBox(width: 4),
                              Text(locationStr, style: TitenTypography.technical(color: tokens.textMetadata)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 13, color: tokens.textMetadata),
                              const SizedBox(width: 4),
                              Text('Diterima: $receivedStr', style: TitenTypography.technical(color: tokens.textMetadata)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Physical Multi-Sensor Telemetry Grid (M10 TelemetryTile)
                Text(
                  'PENGUKURAN MULTI-SENSOR FISIK',
                  style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= 550;
                    final crossAxisCount = isTablet ? 3 : 2;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isTablet ? 1.4 : 1.15,
                      children: [
                        TelemetryTile(
                          label: 'Kemiringan Lereng (MPU6050)',
                          value: tele?.tiltDeg,
                          unit: '°',
                          thresholdDesc: 'Batas Bahaya: > ${HazardConstants.landslideTiltThresholdDeg}°',
                          icon: Icons.screen_rotation_alt,
                          isAnomalous: (tele?.tiltDeg ?? 0) > HazardConstants.landslideTiltThresholdDeg,
                        ),
                        TelemetryTile(
                          label: 'Kelembapan Tanah Relatif',
                          value: tele?.soilMoisturePct,
                          unit: '%',
                          thresholdDesc: 'Kejenuhan Kritis: > ${HazardConstants.landslideSoilMoistureThreshold}%',
                          icon: Icons.water_drop_outlined,
                          isAnomalous: (tele?.soilMoisturePct ?? 0) > HazardConstants.landslideSoilMoistureThreshold,
                        ),
                        TelemetryTile(
                          label: 'Suhu Lingkungan (DHT22)',
                          value: tele?.airTempC,
                          unit: '°C',
                          thresholdDesc: 'Suhu Ekstrem: > ${HazardConstants.karhutlaTempThresholdC}°C',
                          icon: Icons.thermostat_outlined,
                          isAnomalous: (tele?.airTempC ?? 0) > HazardConstants.karhutlaTempThresholdC,
                        ),
                        TelemetryTile(
                          label: 'Kelembapan Udara (DHT22)',
                          value: tele?.airHumidityPct,
                          unit: '%RH',
                          thresholdDesc: 'Udara Kering: < ${HazardConstants.karhutlaHumidityThreshold}%',
                          icon: Icons.air,
                          isAnomalous: tele?.airHumidityPct != null &&
                              tele!.airHumidityPct! < HazardConstants.karhutlaHumidityThreshold,
                        ),
                        TelemetryTile(
                          label: 'Estimasi Baterai',
                          value: node.batteryPct,
                          unit: '%',
                          thresholdDesc: 'Baterai Minimum: 20%',
                          icon: Icons.battery_charging_full,
                        ),
                        TelemetryTile(
                          label: 'Kekuatan Sinyal (LoRa RSSI)',
                          value: node.loraRssi,
                          unit: 'dBm',
                          thresholdDesc: node.loraSnr != null ? 'SNR: ${node.loraSnr} dB' : null,
                          icon: Icons.wifi_tethering,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 3. Sparkline Historical Trend (M11 Sparkline)
                StreamBuilder(
                  stream: repo.watchTelemetryHistory(nodeId),
                  builder: (context, snapshot) {
                    final history = snapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SparklineWidget(
                          title: 'Tren Kemiringan Lereng (°)',
                          unit: '°',
                          history: history,
                          valueExtractor: (t) => t.tiltDeg,
                          lineColor: tokens.critical.fg,
                        ),
                        const SizedBox(height: 10),
                        SparklineWidget(
                          title: 'Tren Kelembapan Tanah Relatif (%)',
                          unit: '%',
                          history: history,
                          valueExtractor: (t) => t.soilMoisturePct,
                          lineColor: tokens.syncing.fg,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 4. Confirmed Relay Actuation Card (M12/M13/M14)
                RelayControlCard(
                  nodeId: node.nodeId,
                  nodeName: node.name,
                ),

                const SizedBox(height: 16),

                // 5. Radio Profile Metadata
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.surfacePanel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.borderSubtle, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'METADATA PROFIL HARDWARE & RADIO',
                        style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      _row(tokens, 'Modul Radio', 'LoRa SX1278 (433.0 MHz SPI)'),
                      _row(tokens, 'Pinout CS/RST/DIO0', 'GPIO 5 / GPIO 14 / GPIO 2'),
                      _row(tokens, 'Sensor MPU6050', 'I2C (SDA GPIO 21, SCL GPIO 22)'),
                      _row(tokens, 'Sensor DHT22 / Soil', 'GPIO 4 / GPIO 34 (ADC1)'),
                      _row(tokens, 'Output Relay Sirine', 'GPIO 25 (Active High Transistor Drive)'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const CacheStatusFooter(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _row(TitenTokens tokens, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TitenTypography.metadata(color: tokens.textSecondary).copyWith(fontSize: 12)),
          Text(value, style: TitenTypography.technical(color: tokens.textPrimary).copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
