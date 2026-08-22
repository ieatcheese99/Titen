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

class SensorMapScreen extends ConsumerStatefulWidget {
  const SensorMapScreen({super.key});

  @override
  ConsumerState<SensorMapScreen> createState() => _SensorMapScreenState();
}

class _SensorMapScreenState extends ConsumerState<SensorMapScreen> {
  final MapController _mapController = MapController();
  String _selectedFilter = 'all'; // 'all', 'landslide', 'karhutla', 'danger'

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(allNodesProvider);
    final allNodes = nodesAsync.value ?? [];

    final filteredNodes = allNodes.where((n) {
      if (_selectedFilter == 'landslide') return n.nodeType == 'landslide' || n.nodeType == 'combo';
      if (_selectedFilter == 'karhutla') return n.nodeType == 'karhutla' || n.nodeType == 'combo';
      if (_selectedFilter == 'danger') return n.lastStatusLevel > 0;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Peta Sebaran Sensor IoT', style: TitenTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Fokus ke Area Sensor',
            onPressed: () {
              _mapController.move(const LatLng(-6.9150, 107.6100), 14.2);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Fullscreen Map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-6.9150, 107.6100),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trilogy.titen',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              MarkerLayer(
                markers: filteredNodes.map((node) {
                  final color = getStatusColor(node.lastStatusLevel, node.lastHazardType);
                  return Marker(
                    point: LatLng(node.latitude, node.longitude),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showNodeDetails(context, node),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
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

          // 2. Top Filter Chips
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Semua (${allNodes.length})', 'all'),
                  const SizedBox(width: 8),
                  _filterChip('Zona Longsor', 'landslide'),
                  const SizedBox(width: 8),
                  _filterChip('Zona Karhutla', 'karhutla'),
                  const SizedBox(width: 8),
                  _filterChip('Anomali / Awas', 'danger'),
                ],
              ),
            ),
          ),

          // 3. Bottom Floating Legend Card
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: TitenColors.surfaceWhite.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TitenColors.outlineBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legendItem('Aman', TitenColors.statusAman),
                  _legendItem('Waspada', TitenColors.statusWaspada),
                  _legendItem('Siaga', TitenColors.statusSiaga),
                  _legendItem('Awas Longsor', TitenColors.statusAwasLongsor),
                  _legendItem('Awas Karhutla', TitenColors.statusAwasKarhutla),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: TitenColors.primaryAccent,
      backgroundColor: TitenColors.surfaceWhite,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : TitenColors.textMain,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? TitenColors.primaryAccent : TitenColors.outlineBorder,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TitenTypography.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showNodeDetails(BuildContext context, SensorNode node) {
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(node.name, style: TitenTypography.titleLarge),
                      Text(
                        'Koordinat: ${node.latitude.toStringAsFixed(4)}, ${node.longitude.toStringAsFixed(4)}',
                        style: TitenTypography.dataLabel,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _teleBox('Kemiringan', '${tele?.tiltDeg ?? 0}°', Icons.screen_rotation_alt),
                  _teleBox('Kelembapan', '${tele?.soilMoisturePct ?? 0}%', Icons.water_drop),
                  _teleBox('Suhu', '${tele?.airTempC ?? 0}°C', Icons.thermostat),
                  _teleBox('Baterai', '${node.batteryPct}%', Icons.battery_charging_full),
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
    return Column(
      children: [
        Icon(icon, size: 20, color: TitenColors.primaryAccent),
        const SizedBox(height: 4),
        Text(value, style: TitenTypography.dataValue.copyWith(fontSize: 16)),
        Text(label, style: TitenTypography.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }
}
