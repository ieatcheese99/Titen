import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../dashboard/application/dashboard_providers.dart';

class SensorListScreen extends ConsumerStatefulWidget {
  const SensorListScreen({super.key});

  @override
  ConsumerState<SensorListScreen> createState() => _SensorListScreenState();
}

class _SensorListScreenState extends ConsumerState<SensorListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(allNodesProvider);
    final nodes = nodesAsync.value ?? [];

    final filtered = nodes.where((n) {
      if (_searchQuery.isEmpty) return true;
      return n.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.nodeId.toString().contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Node Sensor IoT', style: TitenTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari sensor berdasarkan nama atau ID...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            // 2. Hardware Fleet Stats Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TitenColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TitenColors.outlineBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _fleetStat('Total Node', '${nodes.length}', Icons.sensors),
                  const _VerticalDivider(),
                  _fleetStat('Online', '${nodes.where((n) => n.isOnline).length}', Icons.check_circle_outline, TitenColors.statusAman),
                  const _VerticalDivider(),
                  _fleetStat('LoRa Band', '915 MHz', Icons.radio),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Node List Section
            Text('SELURUH TITIK SENSOR LERENG & HUTAN:', style: TitenTypography.dataLabel),
            const SizedBox(height: 10),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 40, color: TitenColors.textMuted),
                      const SizedBox(height: 8),
                      Text('Tidak ada sensor yang cocok dengan pencarian.', style: TitenTypography.bodyMedium),
                    ],
                  ),
                ),
              )
            else
              ...filtered.map((node) {
                final color = getStatusColor(node.lastStatusLevel, node.lastHazardType);
                final tele = node.lastTelemetry;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => context.go('/sensors/${node.nodeId}'),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Node Name + Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: color.withOpacity(0.12),
                                    child: Text(
                                      '0${node.nodeId}',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    node.name,
                                    style: TitenTypography.titleLarge.copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: color.withOpacity(0.4)),
                                ),
                                child: Text(
                                  node.statusText,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Middle: Live Metrics Pills
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _metricPill('Kemiringan', '${tele?.tiltDeg ?? 0}°', tele?.isLandslideHazard ?? false),
                              _metricPill('Kelembapan', '${tele?.soilMoisturePct ?? 0}%', tele?.isLandslideHazard ?? false),
                              _metricPill('Suhu', '${tele?.airTempC ?? 0}°C', tele?.isKarhutlaHazard ?? false),
                              _metricPill('Udara', '${tele?.airHumidityPct ?? 0}%', tele?.isKarhutlaHazard ?? false),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Bottom Row: Battery, Signal RSSI, Last Seen
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.battery_charging_full, size: 14, color: TitenColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text('${node.batteryPct}% (BMS)', style: TitenTypography.bodySmall),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.cell_tower, size: 14, color: TitenColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text('${node.loraRssi} dBm', style: TitenTypography.bodySmall),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Detail',
                                    style: TitenTypography.bodySmall.copyWith(
                                      color: TitenColors.primaryAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 16, color: TitenColors.primaryAccent),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _fleetStat(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color ?? TitenColors.textMuted),
        const SizedBox(height: 4),
        Text(value, style: TitenTypography.dataValue.copyWith(fontSize: 16)),
        Text(label, style: TitenTypography.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _metricPill(String label, String val, bool isAlert) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAlert ? TitenColors.statusAwasLongsor.withOpacity(0.1) : TitenColors.baseBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAlert ? TitenColors.statusAwasLongsor : TitenColors.outlineBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TitenTypography.dataValue.copyWith(
              fontSize: 12,
              color: isAlert ? TitenColors.statusAwasLongsor : TitenColors.textMain,
            ),
          ),
          Text(
            label,
            style: TitenTypography.bodySmall.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: TitenColors.outlineBorder,
    );
  }
}
