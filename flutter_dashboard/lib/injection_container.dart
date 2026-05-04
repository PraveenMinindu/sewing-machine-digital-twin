import 'package:get_it/get_it.dart';
import 'features/machine_monitor/data/datasources/machine_ws_datasource.dart';
import 'features/machine_monitor/data/repositories/machine_repository_impl.dart';
import 'features/machine_monitor/domain/repositories/machine_repository.dart';
import 'features/machine_monitor/domain/usecases/watch_machine_stream.dart';
import 'features/machine_monitor/presentation/bloc/machine_bloc.dart';

final sl = GetIt.instance;

/// Call once from [main] before [runApp].
void initDependencies() {
  // ── Data ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<MachineWsDatasource>(
    () => MachineWsDatasourceImpl(
      wsUrl: 'ws://localhost:8000/ws/dashboard', // Android emulator host
      // For a physical device: use your machine's LAN IP, e.g. ws://192.168.1.x:8000/ws/dashboard
    ),
  );

  sl.registerLazySingleton<MachineRepository>(
    () => MachineRepositoryImpl(datasource: sl()),
  );

  // ── Domain ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => WatchMachineStream(repository: sl()));

  // ── Presentation ──────────────────────────────────────────────────────────
  sl.registerFactory(() => MachineBloc(watchMachineStream: sl()));
}
