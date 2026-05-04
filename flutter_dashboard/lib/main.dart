import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart';
import 'features/machine_monitor/presentation/bloc/machine_bloc.dart';
import 'features/machine_monitor/presentation/pages/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — industrial dashboards don't rotate
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Force edge-to-edge dark immersion
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  initDependencies();
  runApp(const MicroTwinApp());
}

class MicroTwinApp extends StatelessWidget {
  const MicroTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micro-Twin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF4ADE80),
          surface: const Color(0xFF161B22),
        ),
        fontFamily: 'monospace', // industrial feel; swap for Google Fonts later
      ),
      home: BlocProvider(
        create: (_) => sl<MachineBloc>(),
        child: const Scaffold(body: DashboardPage()),
      ),
    );
  }
}
