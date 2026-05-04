import 'package:equatable/equatable.dart';

/// Pure business entity — zero Flutter/JSON dependencies.
/// The status enum drives every UI decision downstream.
enum MachineStatus {
  green,
  yellow,
  red;

  static MachineStatus fromString(String raw) => switch (raw.toUpperCase()) {
        'GREEN' => MachineStatus.green,
        'YELLOW' => MachineStatus.yellow,
        _ => MachineStatus.red,
      };
}

class MachinePulse extends Equatable {
  const MachinePulse({
    required this.machineId,
    required this.operation,
    required this.timestamp,
    required this.unitsProduced,
    required this.efficiencyPct,
    required this.targetRatePerMin,
    required this.projectedEodUnits,
    required this.trendSlope,
    required this.willMeetTarget,
    required this.status,
  });

  final String machineId;
  final String operation;
  final DateTime timestamp;
  final int unitsProduced;
  final double efficiencyPct;
  final double targetRatePerMin;
  final double projectedEodUnits;
  final double trendSlope; // units/min — positive = improving
  final bool willMeetTarget;
  final MachineStatus status;

  @override
  List<Object?> get props => [
        machineId,
        timestamp,
        unitsProduced,
        efficiencyPct,
        status,
      ];
}
