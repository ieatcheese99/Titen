import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_providers.dart';

final activeSimulationModeProvider = StateProvider<String>((ref) => 'aman');

class SimulationController {
  final Ref ref;
  SimulationController(this.ref);

  void setMode(String mode) {
    ref.read(activeSimulationModeProvider.notifier).state = mode;
    ref.read(nodeRepositoryProvider).triggerSimulation(mode);
  }
}

final simulationControllerProvider = Provider<SimulationController>((ref) {
  return SimulationController(ref);
});
