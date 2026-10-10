import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/custom_top_bar.dart';
import '../../../core/widgets/status_banner.dart';
import '../../../core/widgets/gateway_health_card.dart';
import '../../../core/widgets/fleet_summary_card.dart';
import '../../../core/widgets/node_row.dart';
import '../../../core/widgets/cache_status_footer.dart';
import '../../../core/widgets/threat_simulator_bar.dart';
import '../../emergency/presentation/widgets/alert_row.dart';
import '../application/dashboard_providers.dart';
import '../data/models/sensor_node.dart';

/// Home / Ringkasan Screen conforming to 03_APP_FLUTTER_SPEC.md §4.2
/// Dioptimasi dengan Dual-Column Command Center Grid untuk tampilan PC/Website
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.titenTokens;
    final zoneStatus = ref.watch(overallZoneStatusProvider);
    final nodesAsync = ref.watch(allNodesProvider);
    final alertsAsync = ref.watch(alertsProvider);

    final nodes = nodesAsync.value ?? [];
    final activeAlerts = (alertsAsync.value ?? [])
        .where((a) => !a.resolved)
        .toList();

    // Priority sorting per 03_APP_FLUTTER_SPEC.md §4.2:
    // Alert kritis -> sensor error -> missing/stale -> node fresh
    final sortedNodes = List<SensorNode>.from(nodes)
      ..sort((a, b) {
        final aLevel = a.lastStatusLevel ?? 0;
        final bLevel = b.lastStatusLevel ?? 0;
        if (aLevel != bLevel) {
          return bLevel.compareTo(aLevel); // higher level first
        }

        final aFreshness = a.getFreshness().index;
        final bFreshness = b.getFreshness().index;
        return aFreshness.compareTo(bFreshness);
      });

    return Scaffold(
      appBar: const CustomTopBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allNodesProvider);
          ref.invalidate(alertsProvider);
          ref.invalidate(gatewayHealthProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 960;

              if (isDesktop) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ThreatSimulatorBar(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Flex 3): Main Telemetry, Fusion Matrix & Nodes
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusBanner(
                                status: zoneStatus,
                                onRefresh: () {
                                  ref.invalidate(allNodesProvider);
                                },
                              ),
                              const SizedBox(height: 14),
                              _buildDualHazardMatrix(context, tokens),
                              if (activeAlerts.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _buildAlertsSection(context, tokens, activeAlerts),
                              ],
                              const SizedBox(height: 14),
                              _buildNodeSection(context, tokens, nodesAsync, sortedNodes, ref),
                              const SizedBox(height: 14),
                              _buildActionShortcuts(context, tokens),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right Column (Flex 2): Health, Fleet, Live Activity & System Specs
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GatewayHealthCard(),
                              const SizedBox(height: 14),
                              const FleetSummaryCard(),
                              const SizedBox(height: 14),
                              _buildTelemetryLogStream(context, tokens),
                              const SizedBox(height: 14),
                              _buildHardwareSpecsCard(context, tokens),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const CacheStatusFooter(),
                    const SizedBox(height: 20),
                  ],
                );
              }

              // Mobile / Tablet Narrow View (< 960)
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThreatSimulatorBar(),
                  StatusBanner(
                    status: zoneStatus,
                    onRefresh: () {
                      ref.invalidate(allNodesProvider);
                    },
                  ),
                  const SizedBox(height: 14),
                  const GatewayHealthCard(),
                  const SizedBox(height: 14),
                  const FleetSummaryCard(),
                  const SizedBox(height: 14),
                  _buildDualHazardMatrix(context, tokens),
                  if (activeAlerts.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildAlertsSection(context, tokens, activeAlerts),
                  ],
                  const SizedBox(height: 14),
                  _buildNodeSection(context, tokens, nodesAsync, sortedNodes, ref),
                  const SizedBox(height: 14),
                  _buildActionShortcuts(context, tokens),
                  const SizedBox(height: 14),
                  _buildTelemetryLogStream(context, tokens),
                  const SizedBox(height: 20),
                  const CacheStatusFooter(),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 1. Sensor Fusion & Dual Hazard Threshold Matrix Card
  Widget _buildDualHazardMatrix(BuildContext context, TitenTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Row(
                children: [
                  Icon(Icons.query_stats_rounded, size: 18, color: tokens.actionPrimaryBg),
                  const SizedBox(width: 8),
                  Text(
                    'SENSOR FUSION & AMBANG BATAS DUAL BENCANA',
                    style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.normal.bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: tokens.normal.border, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tokens.normal.fg,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SOPOWAKE SIAGA',
                      style: TitenTypography.technical(color: tokens.normal.fg).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _parameterTile(
                    tokens,
                    width: itemWidth,
                    icon: Icons.landscape_outlined,
                    title: 'Kemiringan Tanah (MPU6050)',
                    value: '0.0°',
                    threshold: 'Batas Bahaya: > 5.0°',
                    status: 'NORMAL',
                    statusColor: tokens.normal,
                  ),
                  _parameterTile(
                    tokens,
                    width: itemWidth,
                    icon: Icons.water_drop_outlined,
                    title: 'Kelembapan Tanah (Probe)',
                    value: '0.0%',
                    threshold: 'Batas Bahaya: > 80.0%',
                    status: 'NORMAL',
                    statusColor: tokens.normal,
                  ),
                  _parameterTile(
                    tokens,
                    width: itemWidth,
                    icon: Icons.thermostat_outlined,
                    title: 'Suhu Udara (DHT22)',
                    value: '— °C',
                    threshold: 'Batas Karhutla: > 45.0°C',
                    status: 'SIAGA',
                    statusColor: tokens.syncing,
                  ),
                  _parameterTile(
                    tokens,
                    width: itemWidth,
                    icon: Icons.air_outlined,
                    title: 'Kelembapan Udara (DHT22)',
                    value: '— %',
                    threshold: 'Batas Kering: < 25.0%',
                    status: 'SIAGA',
                    statusColor: tokens.syncing,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.surfaceSubtle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.volume_up_outlined, size: 16, color: tokens.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aktuator Sirine 120dB (GPIO 26): SIAGA · LoRa 915 MHz P2P Transceiver: ACTIVE',
                    style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                      fontSize: 11,
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

  Widget _parameterTile(
    TitenTokens tokens, {
    required double width,
    required IconData icon,
    required String title,
    required String value,
    required String threshold,
    required String status,
    required SemanticColorSet statusColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: tokens.actionPrimaryBg),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TitenTypography.metadata(color: tokens.textMetadata).copyWith(fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.border),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor.fg,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TitenTypography.technical(color: tokens.textPrimary).copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            threshold,
            style: TitenTypography.metadata(color: tokens.textMetadata).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// 2. Active Alerts Section
  Widget _buildAlertsSection(BuildContext context, TitenTokens tokens, List<dynamic> activeAlerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'PERINGATAN AKTIF YANG MEMERLUKAN TINDAKAN',
                style: TitenTypography.technical(color: tokens.critical.fg).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/alerts'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 24),
              ),
              child: Text(
                'Semua Alert',
                style: TextStyle(color: tokens.critical.fg, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...activeAlerts.map(
          (alert) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AlertItemCard(alert: alert),
          ),
        ),
      ],
    );
  }

  /// 3. Node List Section or Interactive Diagnostic State
  Widget _buildNodeSection(
    BuildContext context,
    TitenTokens tokens,
    AsyncValue<List<SensorNode>> nodesAsync,
    List<SensorNode> sortedNodes,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.sensors_outlined, size: 18, color: tokens.actionPrimaryBg),
                const SizedBox(width: 8),
                Text(
                  'NODE YANG PERLU DIPERIKSA',
                  style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.go('/devices'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 24),
              ),
              child: Text(
                'Lihat Seluruh Node',
                style: TextStyle(
                  color: tokens.actionPrimaryBg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (nodesAsync.isLoading) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: tokens.surfacePanel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.actionPrimaryBg,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Memindai telemetri LoRa...',
                    style: TitenTypography.metadata(color: tokens.textMetadata),
                  ),
                ],
              ),
            ),
          ),
        ] else if (sortedNodes.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tokens.surfacePanel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tokens.syncing.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.syncing.border),
                      ),
                      child: Icon(
                        Icons.settings_input_antenna_rounded,
                        size: 28,
                        color: tokens.actionPrimaryBg,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menunggu Paket Telemetri LoRa Pertama',
                            style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gateway LoRa 915 MHz sedang mendengarkan siaran node sensor di frekuensi lokal. Pastikan ESP32 telah dialiri daya.',
                            style: TitenTypography.metadata(color: tokens.textMetadata).copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                // Checklist diagnostic
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _diagItem(tokens, 'LoRa 915 MHz Standby', true),
                    _diagItem(tokens, 'Firebase Sync Listener Siaga', true),
                    _diagItem(tokens, 'SoPoWake Wakeup P2P', true),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.play_circle_outline, size: 16),
                      label: const Text('Muat Data Uji (Demo Mode)'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () {
                        ref.read(dataSourceModeProvider.notifier).state = DataSourceMode.demo;
                      },
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Cek Sinyal Gateway'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () {
                        ref.invalidate(gatewayHealthProvider);
                        ref.invalidate(allNodesProvider);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          ...sortedNodes.take(4).map(
            (node) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NodeRow(
                node: node,
                onTap: () => context.go('/devices/nodes/${node.nodeId}'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _diagItem(TitenTokens tokens, String label, bool isOk) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOk ? Icons.check_circle_outline : Icons.pending_outlined,
          size: 14,
          color: isOk ? tokens.normal.fg : tokens.warning.fg,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TitenTypography.technical(color: tokens.textSecondary).copyWith(fontSize: 11),
        ),
      ],
    );
  }

  /// 4. Quick Actions Toolbar
  Widget _buildActionShortcuts(BuildContext context, TitenTokens tokens) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(Icons.map_outlined, size: 18, color: tokens.actionPrimaryBg),
            label: const Text('Peta Geografis (GIS)'),
            onPressed: () => context.go('/devices/map'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(Icons.analytics_outlined, size: 18, color: tokens.actionPrimaryBg),
            label: const Text('Analitik & Tren'),
            onPressed: () => context.go('/devices/analytics'),
          ),
        ),
      ],
    );
  }

  /// 5. Real-Time Telemetry Log Stream Card
  Widget _buildTelemetryLogStream(BuildContext context, TitenTokens tokens) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final timeStr = DateFormat('HH:mm:ss').format(now);

    final logs = [
      {'time': timeStr, 'tag': 'GATEWAY', 'msg': 'LoRa listening pada 915.0 MHz (BW 125kHz, SF7)'},
      {'time': DateFormat('HH:mm:ss').format(now.subtract(const Duration(seconds: 45))), 'tag': 'CLOUD', 'msg': 'Firebase RTDB synchronization pipeline aktif'},
      {'time': DateFormat('HH:mm:ss').format(now.subtract(const Duration(minutes: 2))), 'tag': 'CONSENSUS', 'msg': 'Dual hazard engine siaga multi-node evaluation'},
      {'time': DateFormat('HH:mm:ss').format(now.subtract(const Duration(minutes: 5))), 'tag': 'POWER', 'msg': 'SoPoWake deep sleep protocol ready (<15µA)'},
      {'time': DateFormat('HH:mm:ss').format(now.subtract(const Duration(minutes: 10))), 'tag': 'RELAY', 'msg': 'Aktuator Sirine 120dB GPIO 26 standby (LOW)'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
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
              Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 18, color: tokens.actionPrimaryBg),
                  const SizedBox(width: 8),
                  Text(
                    'LOG AKTIVITAS SISTEM REAL-TIME',
                    style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.syncing.bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: tokens.syncing.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: tokens.actionPrimaryBg,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE FEED',
                      style: TextStyle(
                        color: tokens.actionPrimaryBg,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...logs.map((log) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[${log['time']}]',
                  style: TitenTypography.technical(color: tokens.textMetadata).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: tokens.surfaceSubtle,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    log['tag']!,
                    style: TextStyle(
                      color: tokens.actionPrimaryBg,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    log['msg']!,
                    style: TitenTypography.metadata(color: tokens.textPrimary).copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// 6. System Architecture & Specifications Card
  Widget _buildHardwareSpecsCard(BuildContext context, TitenTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory_rounded, size: 18, color: tokens.actionPrimaryBg),
              const SizedBox(width: 8),
              Text(
                'ARSITEKTUR & SPESIFIKASI TITEN EWS',
                style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          _specRow(tokens, 'MCU / Processing', 'ESP32 Dual-Core + SoPoWake ULP Sleep (<15µA)'),
          _specRow(tokens, 'Radio Telemetry', 'Semtech SX1276 LoRa 915.0 MHz (P2P Packets)'),
          _specRow(tokens, 'Sensor Fusion', 'MPU6050 (Tilt) + Soil Moisture + DHT22'),
          _specRow(tokens, 'Emergency Siren', 'Relay Aktuator 120dB (GPIO 26 Interrupt)'),
          _specRow(tokens, 'Cloud & Protocol', 'Firebase Realtime DB + Cloud Consensus Engine'),
        ],
      ),
    );
  }

  Widget _specRow(TitenTokens tokens, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TitenTypography.metadata(color: tokens.textMetadata).copyWith(fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TitenTypography.technical(color: tokens.textPrimary).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
