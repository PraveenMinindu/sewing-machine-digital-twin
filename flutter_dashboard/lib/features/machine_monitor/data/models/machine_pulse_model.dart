import 'package:micro_twin_dashboard/features/machine_monitor/domain/entities/machine_pulse.dart';

/// Data model — knows about JSON.
/// The Domain entity [MachinePulse] is JSON-agnostic by design.
class MachinePulseModel extends MachinePulse {
  const MachinePulseModel({
    required super.machineId,
    required super.operation,
    required super.timestamp,
    required super.unitsProduced,
    required super.efficiencyPct,
    required super.targetRatePerMin,
    required super.projectedEodUnits,
    required super.trendSlope,
    required super.willMeetTarget,
    required super.status,
  });

  factory MachinePulseModel.fromJson(Map<String, dynamic> json) {
    return MachinePulseModel(
      machineId: json['machine_id'] as String,
      operation: json['operation'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      unitsProduced: json['units_produced'] as int,
      efficiencyPct: (json['efficiency_pct'] as num).toDouble(),
      targetRatePerMin: (json['target_rate_per_min'] as num).toDouble(),
      projectedEodUnits: (json['projected_eod_units'] as num).toDouble(),
      trendSlope: (json['trend_slope'] as num).toDouble(),
      willMeetTarget: json['will_meet_target'] as bool,
      status: MachineStatus.fromString(json['status'] as String),
    );
  }
}
