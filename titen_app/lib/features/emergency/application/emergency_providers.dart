import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/application/dashboard_providers.dart';

/// Command Execution Status per 03_APP_FLUTTER_SPEC.md §6
enum CommandStatus {
  idle,
  requested,
  accepted,
  executing,
  succeeded,
  failed,
  expired;

  String get label {
    switch (this) {
      case CommandStatus.idle:
        return 'Siap';
      case CommandStatus.requested:
        return 'Permintaan Terkirim';
      case CommandStatus.accepted:
        return 'Diterima Server';
      case CommandStatus.executing:
        return 'Perangkat Menjalankan...';
      case CommandStatus.succeeded:
        return 'Eksekusi Berhasil';
      case CommandStatus.failed:
        return 'Eksekusi Gagal';
      case CommandStatus.expired:
        return 'Perintah Kadaluarsa';
    }
  }
}

final sirenActiveStateProvider = StateProvider<bool>((ref) => false);
final sirenTestingInProgressProvider = StateProvider<bool>((ref) => false);
final commandStatusProvider = StateProvider<CommandStatus>((ref) => CommandStatus.idle);
final lastCommandMessageProvider = StateProvider<String?>((ref) => null);

class EmergencyController {
  final Ref ref;
  EmergencyController(this.ref);

  /// Hardware relay command with confirmed lifecycle per 03_APP_FLUTTER_SPEC.md §6
  Future<bool> executeSirenCommand(int nodeId, bool enable, {int durationSec = 30}) async {
    ref.read(commandStatusProvider.notifier).state = CommandStatus.requested;
    ref.read(lastCommandMessageProvider.notifier).state =
        'Mengirim sinyal aktuasi ke Node ${nodeId.toString().padLeft(2, '0')}...';

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      ref.read(commandStatusProvider.notifier).state = CommandStatus.accepted;

      final repo = ref.read(nodeRepositoryProvider);
      ref.read(commandStatusProvider.notifier).state = CommandStatus.executing;
      ref.read(lastCommandMessageProvider.notifier).state =
          'Perangkat memproses perintah relay...';

      final success = await repo.triggerSirenCommand(nodeId, enable, durationSec: durationSec);

      if (success) {
        ref.read(commandStatusProvider.notifier).state = CommandStatus.succeeded;
        ref.read(sirenActiveStateProvider.notifier).state = enable;
        ref.read(lastCommandMessageProvider.notifier).state = enable
            ? 'Output relay dikonfirmasi ON oleh firmware.'
            : 'Output relay dikonfirmasi OFF oleh firmware.';
      } else {
        ref.read(commandStatusProvider.notifier).state = CommandStatus.failed;
        ref.read(lastCommandMessageProvider.notifier).state =
            'Gagal: Gateway / Node tidak memberikan respon ACK eksekusi.';
      }
      return success;
    } catch (e) {
      ref.read(commandStatusProvider.notifier).state = CommandStatus.failed;
      ref.read(lastCommandMessageProvider.notifier).state = 'Kesalahan sistem: $e';
      return false;
    }
  }

  /// Alert acknowledgment
  Future<bool> acknowledgeAlert(String alertId, [String actor = 'Petugas Lapangan']) async {
    final repo = ref.read(nodeRepositoryProvider);
    return repo.acknowledgeAlert(alertId, actor);
  }

  /// Alert resolution
  Future<bool> resolveAlert(String alertId) async {
    final repo = ref.read(nodeRepositoryProvider);
    return repo.resolveAlert(alertId);
  }

  /// Backward-compatible test method
  Future<bool> testSiren(String pin) async {
    ref.read(sirenTestingInProgressProvider.notifier).state = true;
    try {
      return executeSirenCommand(1, true, durationSec: 15);
    } finally {
      ref.read(sirenTestingInProgressProvider.notifier).state = false;
    }
  }

  void stopSiren() {
    executeSirenCommand(1, false);
  }
}

final emergencyControllerProvider = Provider<EmergencyController>((ref) {
  return EmergencyController(ref);
});
