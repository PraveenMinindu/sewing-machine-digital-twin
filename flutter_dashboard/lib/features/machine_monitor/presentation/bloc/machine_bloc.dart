import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/domain/usecases/watch_machine_stream.dart';
import 'machine_event.dart';
import 'machine_state.dart';

class MachineBloc extends Bloc<MachineEvent, MachineState> {
  MachineBloc({required WatchMachineStream watchMachineStream})
      : _watchMachineStream = watchMachineStream,
        super(const MachineInitial()) {
    on<MachineStreamStarted>(_onStreamStarted);
    on<MachinePulseReceived>(_onPulseReceived);
    on<MachineStreamErrored>(_onStreamErrored);
  }

  final WatchMachineStream _watchMachineStream;
  StreamSubscription? _subscription;

  Future<void> _onStreamStarted(
    MachineStreamStarted event,
    Emitter<MachineState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _watchMachineStream().listen(
      (result) => result.fold(
        (failure) => add(MachineStreamErrored(failure.message)),
        (pulse) => add(MachinePulseReceived(pulse)),
      ),
    );
  }

  void _onPulseReceived(
    MachinePulseReceived event,
    Emitter<MachineState> emit,
  ) =>
      emit(MachineUpdated(event.pulse));

  void _onStreamErrored(
    MachineStreamErrored event,
    Emitter<MachineState> emit,
  ) =>
      emit(MachineError(event.message));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
