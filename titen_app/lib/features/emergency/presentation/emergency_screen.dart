import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/pin_modal.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/emergency_providers.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final alerts = alertsAsync.value ?? [];
    final activeAlert = alerts.where((a) => !a.resolved).firstOrNull;
    final isSirenActive = ref.watch(sirenActiveStateProvider);
    final isSirenTesting = ref.watch(sirenTestingInProgressProvider);
    final emergencyController = ref.read(emergencyControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pusat Darurat & Sirine EWS', style: TitenTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Current Threat / Active Alert Hero
            if (activeAlert != null)
              _buildActiveThreatHero(context, activeAlert)
            else
              _buildSafeHero(),

            const SizedBox(height: 20),

            // 2. Siren Test & Control Card (US-05 with PIN Modal)
            _buildSirenControlCard(context, ref, isSirenActive, isSirenTesting, emergencyController),

            const SizedBox(height: 20),

            // 3. Multi-Node Consensus Details
            _buildConsensusInfoCard(),

            const SizedBox(height: 20),

            // 4. Evacuation Protocol Guide
            _buildEvacuationProtocolCard(),

            const SizedBox(height: 20),

            // 5. Emergency Hotlines
            _buildHotlinesCard(context),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveThreatHero(BuildContext context, dynamic alert) {
    final isKarhutla = alert.hazardType == 2;
    final color = isKarhutla ? TitenColors.statusAwasKarhutla : TitenColors.statusAwasLongsor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TitenTypography.titleLarge.copyWith(color: color, fontSize: 16),
                    ),
                    Text(
                      'STATUS AWAS TINGKAT 3 — VALIDASI MULTI-NODE',
                      style: TitenTypography.dataLabel.copyWith(color: color, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(alert.description, style: TitenTypography.bodyMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: color),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Broadcast Evakuasi Warga'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pesan Evakuasi Darurat Disiarkan via FCM & SMS!')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafeHero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TitenColors.statusAman.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TitenColors.statusAman),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: TitenColors.statusAman,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sistem Siaga Normal', style: TitenTypography.titleLarge.copyWith(color: TitenColors.statusAman)),
                Text(
                  'Tidak ada ancaman aktif yang tervalidasi oleh Multi-Node Consensus.',
                  style: TitenTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSirenControlCard(
    BuildContext context,
    WidgetRef ref,
    bool isSirenActive,
    bool isSirenTesting,
    EmergencyController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TitenColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSirenActive ? TitenColors.statusAwasLongsor : TitenColors.outlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    color: isSirenActive ? TitenColors.statusAwasLongsor : TitenColors.textMain,
                  ),
                  const SizedBox(width: 8),
                  Text('Uji Sirine Lapangan (120dB)', style: TitenTypography.titleLarge.copyWith(fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSirenActive ? TitenColors.statusAwasLongsor.withOpacity(0.12) : TitenColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSirenActive ? 'SIRINE AKTIF' : 'STANDBY',
                  style: TextStyle(
                    color: isSirenActive ? TitenColors.statusAwasLongsor : TitenColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Khusus teknisi lapangan & operator BPBD. Memerlukan verifikasi PIN 4-digit untuk menghindari kepanikan warga (US-05).',
            style: TitenTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          if (isSirenActive)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: TitenColors.textMain),
                    icon: const Icon(Icons.volume_off),
                    label: const Text('Matikan Sirine'),
                    onPressed: () {
                      controller.stopSiren();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Command LoRa SIREN_OFF terkirim ke Edge Node.')),
                      );
                    },
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: isSirenTesting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.lock_clock),
                    label: const Text('Mulai Uji Sirine (Wajib PIN)'),
                    onPressed: isSirenTesting
                        ? null
                        : () async {
                            final verified = await showPinModal(context);
                            if (verified) {
                              final success = await controller.testSiren('1234');
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: TitenColors.statusAwasLongsor,
                                    content: Text('Sirine 120dB & LED Strobe berhasil diaktifkan untuk pengujian!'),
                                  ),
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildConsensusInfoCard() {
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
            children: [
              const Icon(Icons.hub_outlined, color: TitenColors.tacticalCyan, size: 18),
              const SizedBox(width: 8),
              Text('Multi-Node Consensus Engine', style: TitenTypography.titleLarge.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mencegah alarm palsu akibat hewan atau angin sesaat. Status AWAS hanya diaktifkan jika minimal 2 dari 3 node sensor dalam radius 100m mengonfirmasi ancaman yang sama dalam rentang waktu 10 detik.',
            style: TitenTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TitenColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _consStep('Node Sampling', 'ESP32 Fusion', Icons.sensors),
                const Icon(Icons.arrow_forward, size: 14, color: TitenColors.textMuted),
                _consStep('LoRa Transmit', '16-Byte Bitmask', Icons.radio),
                const Icon(Icons.arrow_forward, size: 14, color: TitenColors.textMuted),
                _consStep('Consensus 2/3', 'Verified Alert', Icons.verified),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _consStep(String title, String sub, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: TitenColors.tacticalCyan),
        const SizedBox(height: 2),
        Text(title, style: TitenTypography.dataLabel.copyWith(fontSize: 9)),
        Text(sub, style: TitenTypography.bodySmall.copyWith(fontSize: 8.5, color: TitenColors.textMuted)),
      ],
    );
  }

  Widget _buildEvacuationProtocolCard() {
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
          Text('Protokol Evakuasi Cepat Warga', style: TitenTypography.titleLarge.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          _protocolItem('1', 'Tanah Longsor', 'Jauhi tebing dan lereng curam, evakuasi segera menuju Posko Balai Desa.'),
          const SizedBox(height: 8),
          _protocolItem('2', 'Kebakaran Hutan', 'Gunakan masker basah, hindari jalur asap tebal, dan kumpul di Lapangan Terbuka.'),
          const SizedBox(height: 8),
          _protocolItem('3', 'Koordinasi Petugas', 'Ikuti arahan Tim SAR dan BPBD melalui sirine dan notifikasi aplikasi.'),
        ],
      ),
    );
  }

  Widget _protocolItem(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: TitenColors.primaryAccent.withOpacity(0.12),
          child: Text(num, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TitenColors.primaryAccent)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TitenTypography.bodyLarge.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(desc, style: TitenTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHotlinesCard(BuildContext context) {
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
          Text('Kontak Darurat Terintegrasi', style: TitenTypography.titleLarge.copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _hotlineBtn('BPBD Center', '112 / 021-123456')),
              const SizedBox(width: 10),
              Expanded(child: _hotlineBtn('Basarnas / SAR', '115')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hotlineBtn(String label, String number) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.phone, size: 14),
      label: Text('$label ($number)', style: const TextStyle(fontSize: 11)),
      onPressed: () {},
    );
  }
}
