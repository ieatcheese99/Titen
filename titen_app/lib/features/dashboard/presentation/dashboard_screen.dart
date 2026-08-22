import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/status_banner.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/threat_simulator_bar.dart';
import '../../../core/widgets/custom_top_bar.dart';
import '../application/dashboard_providers.dart';
import '../data/models/sensor_node.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoneStatus = ref.watch(overallZoneStatusProvider);
    final telemetry = ref.watch(aggregateTelemetryProvider);
    final nodesAsync = ref.watch(allNodesProvider);
    final nodes = nodesAsync.value ?? [];

    return Scaffold(
      appBar: const CustomTopBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allNodesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Dynamic Status Banner (Matching Reference UI)
              StatusBanner(status: zoneStatus),

              const SizedBox(height: 12),

              // 2. Interactive MAGE 12 Threat Simulator Controller
              const ThreatSimulatorBar(),

              const SizedBox(height: 14),

              // 3. Sensor Network Map Card & Bento Cards Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 750;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Map Card (60% width)
                        Expanded(
                          flex: 6,
                          child: _buildMapCard(context, nodes),
                        ),
                        const SizedBox(width: 16),
                        // Right: Bento Cards Column (40% width)
                        Expanded(
                          flex: 4,
                          child: _buildBentoCards(context, telemetry, zoneStatus.level > 0),
                        ),
                      ],
                    );
                  } else {
                    // Mobile Layout: Stacked vertically
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMapCard(context, nodes),
                        const SizedBox(height: 16),
                        _buildBentoCards(context, telemetry, zoneStatus.level > 0),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              // 4. Quick Node List Summary Card
              _buildNodeStatusOverview(context, nodes),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard(BuildContext context, List<SensorNode> nodes) {
    return Container(
      decoration: BoxDecoration(
        color: TitenColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TitenColors.outlineBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_outlined, size: 18, color: TitenColors.textMain),
                    const SizedBox(width: 8),
                    Text(
                      'Sensor Network Map',
                      style: TitenTypography.titleLarge.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildPillButton('Filters', Icons.filter_list, () {
                      context.go('/map');
                    }),
                    const SizedBox(width: 8),
                    _buildPillButton('Layers', Icons.layers_outlined, () {
                      context.go('/map');
                    }),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Interactive Map Widget
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(-6.9150, 107.6100),
                    initialZoom: 13.8,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.trilogy.titen',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                    MarkerLayer(
                      markers: nodes.map((node) {
                        final color = getStatusColor(node.lastStatusLevel, node.lastHazardType);
                        return Marker(
                          point: LatLng(node.latitude, node.longitude),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () {
                              _showNodeBottomSheet(context, node);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${node.nodeId}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Mini Map Floating Legend / Status Chip
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: TitenColors.surfaceWhite.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TitenColors.outlineBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: TitenColors.statusAman,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${nodes.length} Nodes Active • LoRa 915MHz',
                          style: TitenTypography.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: TitenColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tap to Expand Button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: InkWell(
                    onTap: () => context.go('/map'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: TitenColors.surfaceWhite.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: TitenColors.outlineBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fullscreen, size: 16, color: TitenColors.textMain),
                          const SizedBox(width: 4),
                          Text(
                            'Perbesar Peta',
                            style: TitenTypography.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCards(BuildContext context, AggregateTelemetry tele, bool isDanger) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: BentoCard(
                icon: Icons.water_drop_outlined,
                label: 'Soil Moisture',
                value: '${tele.avgSoilMoisture}%',
                subtitle: tele.avgSoilMoisture > 80.0
                    ? 'Kritis (Bahaya Jenuh)'
                    : (tele.avgSoilMoisture > 60 ? 'Meningkat' : 'Optimal Range'),
                accentColor: tele.avgSoilMoisture > 80.0 ? TitenColors.statusAwasLongsor : TitenColors.tacticalCyan,
                isWarning: tele.avgSoilMoisture > 80.0,
                onTap: () => context.go('/analytics'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BentoCard(
                icon: Icons.thermostat_outlined,
                label: 'Avg Temperature',
                value: '${tele.avgAirTemp}°C',
                subtitle: tele.avgAirTemp > 45.0
                    ? 'Ekstrem (Risiko Api)'
                    : (tele.avgAirTemp > 35 ? 'Suhu Tinggi' : 'Stable'),
                accentColor: tele.avgAirTemp > 45.0 ? TitenColors.statusAwasKarhutla : TitenColors.primaryAccent,
                isWarning: tele.avgAirTemp > 45.0,
                onTap: () => context.go('/analytics'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BentoCard(
                icon: Icons.screen_rotation_alt_rounded,
                label: 'Tilt Angle (Slope)',
                value: '${tele.avgTiltDeg}°',
                subtitle: tele.avgTiltDeg > 5.0 ? 'Pergeseran Kritis!' : 'No Ground Shift',
                accentColor: tele.avgTiltDeg > 5.0 ? TitenColors.statusAwasLongsor : TitenColors.tacticalCyan,
                isWarning: tele.avgTiltDeg > 5.0,
                onTap: () => context.go('/analytics'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BentoCard(
                icon: Icons.air_rounded,
                label: 'Air Humidity',
                value: '${tele.avgAirHumidity}%',
                subtitle: tele.avgAirHumidity < 25.0 ? 'Kering Ekstrem (Karhutla)' : 'Normal Humidity',
                accentColor: tele.avgAirHumidity < 25.0 ? TitenColors.statusAwasKarhutla : TitenColors.primaryAccent,
                isWarning: tele.avgAirHumidity < 25.0,
                onTap: () => context.go('/analytics'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: TitenColors.baseBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TitenColors.outlineBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: TitenColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TitenTypography.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: TitenColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeStatusOverview(BuildContext context, List<SensorNode> nodes) {
    return Container(
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
              Text(
                'Daftar Node Terhubung',
                style: TitenTypography.titleLarge.copyWith(fontSize: 15),
              ),
              TextButton(
                onPressed: () => context.go('/sensors'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...nodes.take(3).map((node) {
            final color = getStatusColor(node.lastStatusLevel, node.lastHazardType);
            return Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.12),
                  child: Text(
                    '${node.nodeId}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(node.name, style: TitenTypography.bodyLarge),
                subtitle: Text(
                  'Tilt: ${node.lastTelemetry?.tiltDeg ?? 0}° • Tanah: ${node.lastTelemetry?.soilMoisturePct ?? 0}% • Suhu: ${node.lastTelemetry?.airTempC ?? 0}°C',
                  style: TitenTypography.bodySmall,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    node.statusText,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {
                  context.go('/sensors/${node.nodeId}');
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showNodeBottomSheet(BuildContext context, SensorNode node) {
    final color = getStatusColor(node.lastStatusLevel, node.lastHazardType);
    final tele = node.lastTelemetry;

    showModalBottomSheet(
      context: context,
      backgroundColor: TitenColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(node.name, style: TitenTypography.titleLarge),
                        Text(
                          'Tipe: ${node.nodeType.toUpperCase()} • Baterai ${node.batteryPct}% • RSSI ${node.loraRssi} dBm',
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
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricColumn('Kemiringan', '${tele?.tiltDeg ?? 0}°', Icons.screen_rotation_alt),
                  _metricColumn('Tanah', '${tele?.soilMoisturePct ?? 0}%', Icons.water_drop),
                  _metricColumn('Suhu', '${tele?.airTempC ?? 0}°C', Icons.thermostat),
                  _metricColumn('Udara', '${tele?.airHumidityPct ?? 0}%', Icons.air),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/sensors/${node.nodeId}');
                  },
                  child: const Text('Buka Detail Sensor Lengkap'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: TitenColors.textMuted),
        const SizedBox(height: 4),
        Text(value, style: TitenTypography.dataValue.copyWith(fontSize: 16)),
        Text(label, style: TitenTypography.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }
}
