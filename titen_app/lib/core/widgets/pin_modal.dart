import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/hazard_constants.dart';

/// Shows 4-Digit Security PIN Modal (US-05) for Technician Siren Test
Future<bool> showPinModal(BuildContext context) async {
  final pinController = TextEditingController();
  String? errorMessage;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: TitenColors.surfaceWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: TitenColors.outlineBorder),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TitenColors.statusSiaga.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: TitenColors.statusSiaga,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifikasi Teknisi',
                        style: TitenTypography.titleLarge.copyWith(fontSize: 17),
                      ),
                      Text(
                        'Uji Sirine Jarak Jauh (120dB)',
                        style: TitenTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan PIN 4-digit teknisi untuk memicu aktivasi sirine lokal tanpa menyebarkan alarm evakuasi ke warga.',
                  style: TitenTypography.bodyMedium.copyWith(
                    color: TitenColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TitenTypography.dataDisplay.copyWith(
                    letterSpacing: 12,
                    fontSize: 22,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••',
                    counterText: '',
                    errorText: errorMessage,
                    filled: true,
                    fillColor: TitenColors.surfaceSubtle,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'PIN Default Demo: ${HazardConstants.defaultSirenPin}',
                    style: TitenTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: TitenColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Batal',
                  style: TextStyle(color: TitenColors.textMuted),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: TitenColors.statusAwasLongsor,
                ),
                onPressed: () {
                  if (pinController.text == HazardConstants.defaultSirenPin) {
                    Navigator.pop(ctx, true);
                  } else {
                    setState(() {
                      errorMessage = 'PIN Salah! Gunakan ${HazardConstants.defaultSirenPin}';
                    });
                  }
                },
                child: const Text('Aktifkan Sirine'),
              ),
            ],
          );
        },
      );
    },
  );

  return result ?? false;
}
