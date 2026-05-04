import 'package:dartz/dartz.dart';
import 'package:micro_twin_dashboard/core/error/failure.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/domain/entities/machine_pulse.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/domain/repositories/machine_repository.dart';

/// Single-responsibility use-case: subscribe to the machine event stream.
/// The BLoC calls this — it never touches the repository directly.
class WatchMachineStream {
  WatchMachineStream({required MachineRepository repository})
      : _repository = repository;

  final MachineRepository _repository;

  Stream<Either<Failure, MachinePulse>> call() =>
      _repository.watchMachinePulses();
}
