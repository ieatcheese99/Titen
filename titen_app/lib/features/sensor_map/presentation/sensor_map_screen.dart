import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../dashboard/data/models/sensor_node.dart';

/// Sensor Map Screen conforming to 03_APP_FLUTTER_SPEC.md §4.1 & §4.3
class SensorMapScreen extends ConsumerStatefulWidget {
  const SensorMapScreen({super.key});

  @override
  ConsumerState<SensorMapScreen> createState() => _SensorMapScreenState();
}

class _SensorMapScreenState extends ConsumerState<SensorMapScreen> {
  final MapController _mapController = MapController();
  String _selectedFilter = 'all'; // 'all', 'landslide', 'karhutla', 'danger'

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.titenTokens;
    final nodesAsync = ref.watch(allNodesProvider);
    final allNodes = nodesAsync.value ?? [];

    // Filter nodes with valid registry coordinates per 03_APP_FLUTTER_SPEC.md §4.1
    final nodesWithLocation = allNodes
        .where((n) => n.hasValidCoordinates)
        .toList();

    final filteredNodes = nodesWithLocation.where((n) {
      if (_selectedFilter == 'landslide') {
        return n.nodeType == 'landslide' || n.nodeType == 'combo';
      }
      if (_selectedFilter == 'karhutla') {
        return n.nodeType == 'karhutla' || n.nodeType == 'combo';
      }
      if (_selectedFilter == 'danger') return (n.lastStatusLevel ?? 0) > 0;
      return true;
    }).toList();

    final unlocatedNodes = allNodes
        .where((n) => !n.hasValidCoordinates)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Peta Sebaran Sensor IoT',
          style: TitenTypography.sectionTitle(
            color: tokens.textPrimary,
          ).copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Fokus ke Area Sensor',
            onPressed: nodesWithLocation.isEmpty
                ? null
                : () {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(
                          nodesWithLocation
                              .map(
                                (node) =>
                                    LatLng(node.latitude!, node.longitude!),
                              )
                              .toList(),
                        ),
                        padding: const EdgeInsets.all(64),
                        maxZoom: 16,
                      ),
                    );
                  },
          ),
        ],
      ),
      body: nodesAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : nodesWithLocation.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 40,
                      color: tokens.textMetadata,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lokasi node belum disetel',
                      style: TitenTypography.sectionTitle(
                        color: tokens.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nodesAsync.hasError
                          ? 'Data lokasi belum dapat dimuat. Periksa koneksi data live.'
                          : 'Tambahkan koordinat lokasi pemasangan agar node dapat ditampilkan di peta.',
                      style: TitenTypography.body(color: tokens.textMetadata),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // 1. Fullscreen Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(
                        nodesWithLocation
                            .map(
                              (node) => LatLng(node.latitude!, node.longitude!),
                            )
                            .toList(),
                      ),
                      padding: const EdgeInsets.all(64),
                      maxZoom: 16,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.trilogy.titen',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                    MarkerLayer(
                      markers: filteredNodes.map((node) {
                        final color = getStatusColor(
                          node.lastStatusLevel,
                          node.lastHazardType,
                        );
                        return Marker(
                          point: LatLng(node.latitude!, node.longitude!),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showNodeDetails(context, node),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${node.nodeId}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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

                // 2. Unlocated Nodes Warning Banner (if any)
                if (unlocatedNodes.isNotEmpty)
                  Positioned(
                    bottom: 80,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surfacePanel,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tokens.borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: tokens.textMetadata,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${unlocatedNodes.length} node belum memiliki koordinat GPS di registry.',
                              style: TitenTypography.metadata(
                                color: tokens.textSecondary,
                              ).copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Floating Filter Controls (Top)
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterButton(
                          'all',
                          'Semua (${nodesWithLocation.length})',
                        ),
                        const SizedBox(width: 8),
                        _filterButton('landslide', 'Lereng / Longsor'),
                        const SizedBox(width: 8),
                        _filterButton('karhutla', 'Sektor Hutan'),
                        const SizedBox(width: 8),
                        _filterButton('danger', 'Ada Anomali'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _filterButton(String filterKey, String label) {
    final tokens = context.titenTokens;
    final isSelected = _selectedFilter == filterKey;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? tokens.actionPrimaryBg : tokens.surfacePanel,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? tokens.actionPrimaryBg : tokens.borderControl,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? tokens.actionPrimaryFg : tokens.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showNodeDetails(BuildContext context, SensorNode node) {
    final tokens = context.titenTokens;
    final color = getStatusColor(node.lastStatusLevel, node.lastHazardType);
    final tele = node.lastTelemetry;

    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.name, style: TitenTypography.titleLarge),
                      Text(
                        'Koordinat: ${node.latitude?.toStringAsFixed(4) ?? "—"}, ${node.longitude?.toStringAsFixed(4) ?? "—"}',
                        style: TitenTypography.dataLabel,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      node.statusText,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _teleBox(
                    'Kemiringan',
                    tele?.tiltDeg != null ? '${tele!.tiltDeg}°' : '—',
                    Icons.screen_rotation_alt,
                  ),
                  _teleBox(
                    'Kelembapan',
                    tele?.soilMoisturePct != null
                        ? '${tele!.soilMoisturePct}%'
                        : '—',
                    Icons.water_drop,
                  ),
                  _teleBox(
                    'Suhu',
                    tele?.airTempC != null ? '${tele!.airTempC}°C' : '—',
                    Icons.thermostat,
                  ),
                  _teleBox(
                    'Baterai',
                    node.batteryPct != null ? '${node.batteryPct}%' : '—',
                    Icons.battery_charging_full,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/devices/nodes/${node.nodeId}');
                  },
                  child: const Text('Buka Detail Node Lengkap'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _teleBox(String label, String value, IconData icon) {
    final tokens = context.titenTokens;
    return Column(
      children: [
        Icon(icon, size: 20, color: tokens.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TitenTypography.valueCompact().copyWith(fontSize: 16),
        ),
        Text(
          label,
          style: TitenTypography.metadata(
            color: tokens.textMetadata,
          ).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
