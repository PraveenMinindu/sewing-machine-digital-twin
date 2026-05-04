import 'package:dartz/dartz.dart';
import 'package:micro_twin_dashboard/core/error/failure.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/domain/entities/machine_pulse.dart';

/// Contract — the data layer implements this; the domain layer depends on it.
abstract class MachineRepository {
  Stream<Either<Failure, MachinePulse>> watchMachinePulses();
}
