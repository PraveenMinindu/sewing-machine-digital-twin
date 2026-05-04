import 'package:equatable/equatable.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/domain/entities/machine_pulse.dart';

abstract class MachineEvent extends Equatable {
  const MachineEvent();
  @override
  List<Object?> get props => [];
}

/// User opened the screen — start subscribing.
class MachineStreamStarted extends MachineEvent {
  const MachineStreamStarted();
}

/// Internal: a new pulse arrived from the WebSocket.
class MachinePulseReceived extends MachineEvent {
  const MachinePulseReceived(this.pulse);
  final MachinePulse pulse;
  @override
  List<Object?> get props => [pulse];
}

/// Internal: something went wrong on the stream.
class MachineStreamErrored extends MachineEvent {
  const MachineStreamErrored(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
