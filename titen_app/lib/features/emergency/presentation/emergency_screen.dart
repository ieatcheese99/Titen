import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/cache_status_footer.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../dashboard/data/models/alert_model.dart';
import 'widgets/alert_row.dart';
import 'widgets/relay_action_sheet.dart';

/// Peringatan & EWS Command Screen conforming to 03_APP_FLUTTER_SPEC.md §8
class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  AlertLifecycle? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final tokens = context.titenTokens;
    final alertsAsync = ref.watch(alertsProvider);
    final alerts = alertsAsync.value ?? [];

    final filteredAlerts = alerts.where((a) {
      if (_selectedFilter == null) return true;
      return a.lifecycle == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pusat Peringatan & Sirine EWS',
          style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(alertsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Confirmed Hardware Siren Actuation Card
              const RelayControlCard(
                nodeId: 1,
                nodeName: 'Node 01 (Sirine Utama)',
              ),

              const SizedBox(height: 20),

              // 2. Alert Lifecycle Filter Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LOG PERINGATAN BENCANA',
                    style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${filteredAlerts.length} Kejadian',
                    style: TitenTypography.technical(color: tokens.textMetadata).copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: _selectedFilter == null,
                      label: Text('Semua (${alerts.length})'),
                      onSelected: (_) => setState(() => _selectedFilter = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedFilter == AlertLifecycle.open,
                      label: Text(
                        'Aktif (${alerts.where((a) => a.lifecycle == AlertLifecycle.open).length})',
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedFilter = selected ? AlertLifecycle.open : null);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedFilter == AlertLifecycle.acknowledged,
                      label: Text(
                        'Diakui (${alerts.where((a) => a.lifecycle == AlertLifecycle.acknowledged).length})',
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedFilter = selected ? AlertLifecycle.acknowledged : null);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedFilter == AlertLifecycle.resolved,
                      label: Text(
                        'Selesai (${alerts.where((a) => a.lifecycle == AlertLifecycle.resolved).length})',
                      ),
                      onSelected: (selected) {
                        setState(() => _selectedFilter = selected ? AlertLifecycle.resolved : null);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Alerts List
              if (alertsAsync.isLoading)
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
                        const SizedBox(height: 10),
                        Text('Memeriksa riwayat peringatan...', style: TitenTypography.metadata(color: tokens.textMetadata)),
                      ],
                    ),
                  ),
                )
              else if (filteredAlerts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: tokens.surfacePanel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 36, color: tokens.normal.fg),
                      const SizedBox(height: 10),
                      Text(
                        'Belum Ada Alert Terverifikasi',
                        style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tidak ada insiden bahaya pada filter ini. Sistem memantau ambang telemetri secara berkelanjutan.',
                        style: TitenTypography.body(color: tokens.textSecondary).copyWith(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...filteredAlerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AlertItemCard(alert: alert),
                  ),
                ),

              const SizedBox(height: 20),

              // 4. Protokol Evakuasi & Hotline
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.surfacePanel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PANDUAN & PROTOKOL EVAKUASI WARGA',
                      style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    _protoItem('1. Status Awas', 'Bunyikan sirine 120dB & arahkan warga ke titik kumpul aman.'),
                    _protoItem('2. Cek Jalur', 'Hindari area lembah sempit dan tebing berlereng > 20°.'),
                    _protoItem('3. Hubungi BPBD', 'Pusdalops BPBD: 112 / Tim Tanggap Bencana Lokal.'),
                  ],
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

  Widget _protoItem(String num, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
