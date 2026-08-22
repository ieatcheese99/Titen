import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/hazard_constants.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../analytics/application/analytics_providers.dart';

class SensorDetailScreen extends ConsumerWidget {
  final int nodeId;

  const SensorDetailScreen({super.key, required this.nodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeAsync = ref.watch(singleNodeProvider(nodeId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Node 0$nodeId', style: TitenTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: nodeAsync.when(
        data: (node) {
          if (node == null) {
            return const Center(child: Text('Sensor tidak ditemukan.'));
          }

          final color = getStatusColor(node.lastStatusLevel, node.lastHazardType);
          final tele = node.lastTelemetry;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Card with Status Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TitenColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TitenColors.outlineBorder),
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
                                Text(node.name, style: TitenTypography.headlineMedium.copyWith(fontSize: 18)),
                                const SizedBox(height: 2),
                                Text(
                                  'Tipe: ${node.nodeType.toUpperCase()} • LoRa 915MHz SX1276',
                                  style: TitenTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color),
                            ),
                            child: Text(
                              node.statusText,
                              style: TextStyle(color: color, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Koordinat: ${node.latitude.toStringAsFixed(4)}, ${node.longitude.toStringAsFixed(4)}',
                            style: TitenTypography.dataLabel.copyWith(fontSize: 10),
                          ),
                          Text(
                            'Last seen: ${DateFormat('HH:mm:ss').format(node.lastSeen)}',
                            style: TitenTypography.dataLabel.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Physical Multi-Sensor Telemetry Section (FR-1.4)
                Text('TELEMETRI MULTI-SENSOR FISIK:', style: TitenTypography.dataLabel),
                const SizedBox(height: 10),

                // Row 1: Soil Moisture & Tilt Angle
                Row(
                  children: [
                    Expanded(
                      child: _teleCard(
                        'Kemiringan Lereng (MPU6050)',
                        '${tele?.tiltDeg ?? 0}°',
                        'Batas Bahaya: > ${HazardConstants.landslideTiltThresholdDeg}°',
                        Icons.screen_rotation_alt,
                        (tele?.tiltDeg ?? 0) > HazardConstants.landslideTiltThresholdDeg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _teleCard(
                        'Kelembapan Tanah (Capacitive)',
                        '${tele?.soilMoisturePct ?? 0}%',
                        'Batas Bahaya: > ${HazardConstants.landslideSoilMoistureThreshold}%',
                        Icons.water_drop,
                        (tele?.soilMoisturePct ?? 0) > HazardConstants.landslideSoilMoistureThreshold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Air Temp & Air Humidity
                Row(
                  children: [
                    Expanded(
                      child: _teleCard(
                        'Suhu Udara (DHT22)',
                        '${tele?.airTempC ?? 0}°C',
                        'Batas Bahaya: > ${HazardConstants.karhutlaTempThresholdC}°C',
                        Icons.thermostat,
                        (tele?.airTempC ?? 0) > HazardConstants.karhutlaTempThresholdC,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _teleCard(
                        'Kelembapan Udara (DHT22)',
                        '${tele?.airHumidityPct ?? 0}%',
                        'Batas Bahaya: < ${HazardConstants.karhutlaHumidityThreshold}%',
                        Icons.air,
                        (tele?.airHumidityPct ?? 0) < HazardConstants.karhutlaHumidityThreshold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Hardware Health & Telemetry Diagnostics (BMS, LoRa)
                Text('KESEHATAN PERANGKAT & JARINGAN:', style: TitenTypography.dataLabel),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TitenColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TitenColors.outlineBorder),
                  ),
                  child: Column(
                    children: [
                      _diagRow('Catu Daya (SoPoWake Solar + 18650 BMS)', '${node.batteryPct}% (Optimal 3.92V)', Icons.solar_power_outlined),
                      const Divider(height: 20),
                      _diagRow('Kekuatan Sinyal Radio (LoRa RSSI)', '${node.loraRssi} dBm (Sangat Baik)', Icons.cell_tower),
                      const Divider(height: 20),
                      _diagRow('Signal-to-Noise Ratio (LoRa SNR)', '${node.loraSnr} dB', Icons.network_check),
                      const Divider(height: 20),
                      _diagRow('Mode Daya Mikrokontroler', 'ESP32 Deep Sleep (< 15µA)', Icons.bedtime_outlined),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.show_chart),
                    label: const Text('Buka Tren Grafik 7-Hari Node Ini'),
                    onPressed: () {
                      ref.read(selectedNodeIdForAnalyticsProvider.notifier).state = node.nodeId;
                      context.go('/analytics');
                    },
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Gagal memuat detail sensor')),
      ),
    );
  }

  Widget _teleCard(String title, String value, String thresholdText, IconData icon, bool isWarning) {
    final color = isWarning ? TitenColors.statusAwasLongsor : TitenColors.primaryAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TitenColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning ? color : TitenColors.outlineBorder,
          width: isWarning ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: color),
              if (isWarning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('BAHAYA', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TitenTypography.dataDisplay.copyWith(fontSize: 22, color: isWarning ? color : TitenColors.textMain)),
          const SizedBox(height: 2),
          Text(title, style: TitenTypography.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(thresholdText, style: TitenTypography.dataLabel.copyWith(fontSize: 9, color: TitenColors.textMuted)),
        ],
      ),
    );
  }

  Widget _diagRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: TitenColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TitenTypography.bodyMedium.copyWith(fontSize: 12.5)),
              Text(value, style: TitenTypography.dataValue.copyWith(fontSize: 12.5, color: TitenColors.primaryAccent)),
            ],
          ),
        ),
      ],
    );
  }
}
