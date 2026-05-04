import 'package:equatable/equatable.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/domain/entities/machine_pulse.dart';

abstract class MachineState extends Equatable {
  const MachineState();
  @override
  List<Object?> get props => [];
}

/// Waiting for the first pulse
class MachineInitial extends MachineState {
  const MachineInitial();
}

/// At least one pulse received and parsed successfully
class MachineUpdated extends MachineState {
  const MachineUpdated(this.pulse);
  final MachinePulse pulse;
  @override
  List<Object?> get props => [pulse];
}

/// Stream/parse error — show an error banner but keep listening
class MachineError extends MachineState {
  const MachineError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
