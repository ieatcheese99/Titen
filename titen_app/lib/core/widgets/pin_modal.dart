import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/hazard_constants.dart';

/// Shows 4-Digit Security PIN Modal for Operator Siren Test per 03_APP_FLUTTER_SPEC.md §6
Future<bool> showPinModal(BuildContext context) async {
  final pinController = TextEditingController();
  final tokens = context.titenTokens;
  String? errorMessage;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: tokens.surfacePanel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: tokens.borderSubtle),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tokens.warning.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.warning.border),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: tokens.warning.fg,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Otorisasi Operator',
                        style: TitenTypography.titleLarge.copyWith(fontSize: 17),
                      ),
                      Text(
                        'Uji Output Sirine EWS',
                        style: TitenTypography.metadata(color: tokens.textMetadata),
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
                  'Masukkan PIN verifikasi untuk memicu uji coba sirine hardware.',
                  style: TitenTypography.body(color: tokens.textSecondary).copyWith(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: TitenTypography.value(color: tokens.textPrimary).copyWith(
                    letterSpacing: 10,
                    fontSize: 22,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••',
                    counterText: '',
                    errorText: errorMessage,
                    filled: true,
                    fillColor: tokens.surfaceSubtle,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'PIN Default Pengujian: ${HazardConstants.defaultSirenPin}',
                    style: TitenTypography.metadata(color: tokens.textMetadata).copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Batal', style: TextStyle(color: tokens.textMetadata)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.critical.fg,
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
                child: const Text('Konfirmasi & Aktifkan'),
              ),
            ],
          );
        },
      );
    },
  );

  return result ?? false;
}
