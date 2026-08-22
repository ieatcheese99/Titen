import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/application/dashboard_providers.dart';

final sirenActiveStateProvider = StateProvider<bool>((ref) => false);
final sirenTestingInProgressProvider = StateProvider<bool>((ref) => false);

class EmergencyController {
  final Ref ref;
  EmergencyController(this.ref);

  Future<bool> testSiren(String pin) async {
    ref.read(sirenTestingInProgressProvider.notifier).state = true;
    try {
      final repo = ref.read(nodeRepositoryProvider);
      final success = await repo.triggerSirenTest(pin);
      if (success) {
        ref.read(sirenActiveStateProvider.notifier).state = true;
      }
      return success;
    } finally {
      ref.read(sirenTestingInProgressProvider.notifier).state = false;
    }
  }

  void stopSiren() {
    ref.read(sirenActiveStateProvider.notifier).state = false;
  }
}

final emergencyControllerProvider = Provider<EmergencyController>((ref) {
  return EmergencyController(ref);
});
