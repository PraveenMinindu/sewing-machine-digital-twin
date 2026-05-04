import 'package:dartz/dartz.dart';
import 'package:micro_twin_dashboard/core/error/failure.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/data/datasources/machine_ws_datasource.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/domain/entities/machine_pulse.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/domain/repositories/machine_repository.dart';

class MachineRepositoryImpl implements MachineRepository {
  MachineRepositoryImpl({required MachineWsDatasource datasource})
      : _datasource = datasource;

  final MachineWsDatasource _datasource;

  @override
  Stream<Either<Failure, MachinePulse>> watchMachinePulses() async* {
    await for (final pulse in _datasource.watchPulses()) {
      yield Right(pulse);
    }
  }
}
