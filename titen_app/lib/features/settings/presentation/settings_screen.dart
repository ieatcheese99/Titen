import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../dashboard/data/models/user_profile.dart';
import '../application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final gateway = ref.watch(loraGatewayStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan & Konfigurasi', style: TitenTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Profile & Role Card
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
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: TitenColors.primaryAccent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.person, color: TitenColors.primaryAccent, size: 26),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: TitenTypography.titleLarge.copyWith(fontSize: 16)),
                            Text(user.location ?? 'Lokasi Wilayah Binaan', style: TitenTypography.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('PILIH PERAN PENGGUNA (ROLE):', style: TitenTypography.dataLabel),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserRole>(
                    initialValue: user.role,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName, style: TitenTypography.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (newRole) {
                      if (newRole != null) {
                        ref.read(userProfileProvider.notifier).state = UserProfile(
                          uid: user.uid,
                          name: user.name,
                          role: newRole,
                          phone: user.phone,
                          location: user.location,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. LoRa IoT Gateway Diagnostics
            Text('STATUS HARDWARE IOT GATEWAY:', style: TitenTypography.dataLabel),
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
                  _infoRow('Status Gateway', gateway['status'] as String, isGreen: true),
                  const Divider(height: 18),
                  _infoRow('Nama Jaringan Gateway', gateway['ssid'] as String),
                  const Divider(height: 18),
                  _infoRow('Frekuensi LoRa', gateway['frequency'] as String),
                  const Divider(height: 18),
                  _infoRow('Kekuatan Sinyal (RSSI)', gateway['rssi'] as String),
                  const Divider(height: 18),
                  _infoRow('Node Sensor Terhubung', '${gateway['nodesConnected']} Unit (Node 01 - 04)'),
                  const Divider(height: 18),
                  _infoRow('Sinkronisasi Cloud', gateway['syncInterval'] as String),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Notification Settings
            Text('PENGATURAN NOTIFIKASI PUSH (FCM):', style: TitenTypography.dataLabel),
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Peringatan AWAS Prioritas Tinggi', style: TitenTypography.bodyLarge),
                    subtitle: Text('Bypass mode senyap jika konsensus longsor/karhutla aktif', style: TitenTypography.bodySmall),
                    value: true,
                    onChanged: (v) {},
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Getaran Sirine Virtual', style: TitenTypography.bodyLarge),
                    subtitle: Text('Pola getaran darurat saat alarm sirine 120dB berbunyi', style: TitenTypography.bodySmall),
                    value: true,
                    onChanged: (v) {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. About App & MAGE 12 Info
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: TitenColors.primaryAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_outlined, color: TitenColors.primaryAccent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Tentang Proyek TITEN', style: TitenTypography.titleLarge.copyWith(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'TITEN (Sistem Peringatan Dini Tanah Longsor & Kebakaran Hutan) dikembangkan oleh Tim TRILOGY dari SMK Budi Luhur, Kota Tangerang untuk kompetisi MAGE 12 (Subtema: Climate Disaster Technology).',
                    style: TitenTypography.bodySmall.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tim Penyusun:\n• Muhammad Zahir Siraj\n• Zabdan Harjati Purnomo\n• Muhammad Rasya Al Faridzi',
                    style: TitenTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TitenTypography.bodyMedium),
        Text(
          value,
          style: TitenTypography.dataValue.copyWith(
            fontSize: 13,
            color: isGreen ? TitenColors.statusAman : TitenColors.textMain,
          ),
        ),
      ],
    );
  }
}
