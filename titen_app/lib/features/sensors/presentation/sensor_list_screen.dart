import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/filter_search.dart';
import '../../../core/widgets/node_row.dart';
import '../../../core/widgets/cache_status_footer.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../dashboard/data/models/sensor_node.dart';

/// Daftar Perangkat Screen conforming to 03_APP_FLUTTER_SPEC.md §4.3
class SensorListScreen extends ConsumerStatefulWidget {
  const SensorListScreen({super.key});

  @override
  ConsumerState<SensorListScreen> createState() => _SensorListScreenState();
}

class _SensorListScreenState extends ConsumerState<SensorListScreen> {
  String _searchQuery = '';
  FreshnessStatus? _selectedFreshness;
  int? _selectedHazardLevel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.titenTokens;
    final nodesAsync = ref.watch(allNodesProvider);
    final nodes = nodesAsync.value ?? [];

    final filtered = nodes.where((n) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = n.name.toLowerCase().contains(q);
        final matchesId = n.nodeId.toString().contains(q) || n.nodeKey.toLowerCase().contains(q);
        if (!matchesName && !matchesId) return false;
      }

      if (_selectedFreshness != null && n.getFreshness() != _selectedFreshness) {
        return false;
      }

      if (_selectedHazardLevel != null && n.lastStatusLevel != _selectedHazardLevel) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daftar Node & Gateway IoT',
          style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Buka Peta Geografis',
            onPressed: () => context.go('/devices/map'),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Analitik Tren',
            onPressed: () => context.go('/devices/analytics'),
          ),
        ],
      ),
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
              // 1. Search Bar (M08 FilterSearch)
              FilterSearch(
                query: _searchQuery,
                onChanged: (val) => setState(() => _searchQuery = val),
                onClear: () => setState(() => _searchQuery = ''),
              ),

              const SizedBox(height: 12),

              // 2. Filter Chips: All, Fresh, Anomaly, Stale
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: _selectedFreshness == null && _selectedHazardLevel == null,
                      label: const Text('Semua'),
                      onSelected: (_) {
                        setState(() {
                          _selectedFreshness = null;
                          _selectedHazardLevel = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedFreshness == FreshnessStatus.fresh,
                      label: const Text('Data Fresh'),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFreshness = selected ? FreshnessStatus.fresh : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedHazardLevel != null,
                      label: const Text('Ada Anomali'),
                      onSelected: (selected) {
                        setState(() {
                          _selectedHazardLevel = selected ? 1 : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedFreshness == FreshnessStatus.stale,
                      label: const Text('Stale / Terlambat'),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFreshness = selected ? FreshnessStatus.stale : null;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Node List Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NODE TERVERIFIKASI (${filtered.length} DITEMUKAN):',
                    style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Total Registry: ${nodes.length}',
                    style: TitenTypography.technical(color: tokens.textMetadata).copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (nodesAsync.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 12),
                        Text('Memuat node dari database...', style: TitenTypography.metadata(color: tokens.textMetadata)),
                      ],
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: tokens.surfacePanel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_outlined, size: 40, color: tokens.textMetadata),
                      const SizedBox(height: 10),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Tidak ada node yang cocok dengan pencarian.'
                            : 'Belum ada data node sensor yang diterima.',
                        style: TitenTypography.body(color: tokens.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pastikan node fisik aktif dan memancarkan paket telemetri LoRa.',
                        style: TitenTypography.metadata(color: tokens.textMetadata),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map(
                  (node) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NodeRow(
                      node: node,
                      onTap: () => context.go('/devices/nodes/${node.nodeId}'),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              const CacheStatusFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
