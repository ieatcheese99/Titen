import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/cache_status_footer.dart';
import 'widgets/field_diagnostics_card.dart';
import 'widgets/preferences_group.dart';

/// Alat & Pengaturan Screen conforming to 03_APP_FLUTTER_SPEC.md §4.1 & §7
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.titenTokens;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alat Lapangan & Pengaturan',
          style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. M21 Field Diagnostics Checklist
            const FieldDiagnosticsCard(),

            const SizedBox(height: 16),

            // 2. M24 Preferences Group (ThemeMode, Haptics, Notifications)
            const PreferencesGroupCard(),

            const SizedBox(height: 16),

            // 3. Provisioning Wizard Card (With Capability Gate per §7.1)
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
                    children: [
                      Icon(Icons.bluetooth_searching, size: 20, color: tokens.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'COMMISSIONING & WIZARD BLE',
                        style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text(
                    'Pemasangan Gateway Baru (ESP32 BLE / SoftAP)',
                    style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fitur commissioning nirkabel membutuhkan build firmware gateway ESP32-S3 dengan modul Espressif Unified Provisioning aktif. Gateway saat ini beroperasi pada mode stasiun radio LoRa mandiri.',
                    style: TitenTypography.body(color: tokens.textSecondary).copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Scan QR / Mulai Wizard (Belum Didukung Firmware)'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Firmware gateway saat ini belum mengumumkan GATT provisioning.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Informasi Proyek Lomba MAGE 12
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TITEN — Sistem Peringatan Dini Bencana Multi-Sensor LoRa',
                    style: TitenTypography.technical(color: tokens.textPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kategori IoT — Multimedia and Game Event (MAGE) 12 ITS Surabaya.\nDesain sistem dan kontrak interaksi: 7 Oktober 2026.',
                    style: TitenTypography.metadata(color: tokens.textMetadata).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const CacheStatusFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
