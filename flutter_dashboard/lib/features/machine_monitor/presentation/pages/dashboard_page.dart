import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/domain/entities/machine_pulse.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/presentation/bloc/machine_bloc.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/presentation/bloc/machine_event.dart';
import 'package:micro_twin_dashboard/features/machine_monitor/presentation/bloc/machine_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    context.read<MachineBloc>().add(const MachineStreamStarted());

    // Pulse ring that fires on every new data point
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Status → color mapping ───────────────────────────────────────────────
  static const _statusColors = {
    MachineStatus.green: Color(0xFF1A3C2E),
    MachineStatus.yellow: Color(0xFF3B2E0A),
    MachineStatus.red: Color(0xFF3B0F0F),
  };

  static const _statusAccents = {
    MachineStatus.green: Color(0xFF4ADE80),
    MachineStatus.yellow: Color(0xFFFBBF24),
    MachineStatus.red: Color(0xFFF87171),
  };

  static const _statusLabels = {
    MachineStatus.green: 'ON TARGET',
    MachineStatus.yellow: 'AT RISK',
    MachineStatus.red: 'OFF TARGET',
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MachineBloc, MachineState>(
      listener: (context, state) {
        // Fire the pulse ring animation on every new data point
        if (state is MachineUpdated) {
          _pulseController.forward(from: 0);
        }
      },
      builder: (context, state) {
        final pulse = state is MachineUpdated ? state.pulse : null;
        final status = pulse?.status ?? MachineStatus.green;
        final bgColor = _statusColors[status]!;
        final accent = _statusAccents[status]!;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          color: bgColor,
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(pulse, accent),
                Expanded(child: _buildBody(pulse, accent, status)),
                _buildBottomBar(pulse, accent),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar(MachinePulse? pulse, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MICRO-TWIN',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pulse?.machineId ?? '—',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          // Live dot
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 24 + 16 * _pulseAnimation.value,
                  height: 24 + 16 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(
                      0.3 * (1 - _pulseAnimation.value),
                    ),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody(MachinePulse? pulse, Color accent, MachineStatus status) {
    if (pulse == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: accent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Awaiting machine pulse…',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildStatusBadge(status, accent),
          const SizedBox(height: 32),
          _buildEfficiencyRing(pulse, accent),
          const SizedBox(height: 32),
          _buildStatGrid(pulse, accent),
          const SizedBox(height: 24),
          _buildPredictionCard(pulse, accent),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Status badge ─────────────────────────────────────────────────────────
  Widget _buildStatusBadge(MachineStatus status, Color accent) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accent.withOpacity(0.4)),
        ),
        child: Text(
          _statusLabels[status]!,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
      ),
    );
  }

  // ─── Efficiency ring ──────────────────────────────────────────────────────
  Widget _buildEfficiencyRing(MachinePulse pulse, Color accent) {
    final pct = pulse.efficiencyPct.clamp(0, 120) / 100;

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background ring
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: 8,
                color: Colors.white10,
              ),
            ),
            // Efficiency arc
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct.toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, value, __) => SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  color: accent,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            // Centre readout
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: pulse.efficiencyPct),
                  duration: const Duration(milliseconds: 500),
                  builder: (_, v, __) => Text(
                    '${v.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const Text(
                  'EFFICIENCY',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stat grid ────────────────────────────────────────────────────────────
  Widget _buildStatGrid(MachinePulse pulse, Color accent) {
    final stats = [
      _StatItem(
        label: 'UNITS PRODUCED',
        value: '${pulse.unitsProduced}',
        unit: 'pcs',
        accent: accent,
      ),
      _StatItem(
        label: 'LAST OP',
        value: pulse.operation.replaceAll('_', ' ').toUpperCase(),
        unit: '',
        accent: accent,
      ),
      _StatItem(
        label: 'TREND',
        value: pulse.trendSlope >= 0
            ? '+${pulse.trendSlope.toStringAsFixed(3)}'
            : pulse.trendSlope.toStringAsFixed(3),
        unit: 'u/min',
        accent: pulse.trendSlope >= 0
            ? const Color(0xFF4ADE80)
            : const Color(0xFFF87171),
      ),
      _StatItem(
        label: 'NEED RATE',
        value: pulse.targetRatePerMin.toStringAsFixed(2),
        unit: 'u/min',
        accent: accent,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: stats.map(_buildStatCard).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  item.value,
                  style: TextStyle(
                    color: item.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    item.unit,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Prediction card ──────────────────────────────────────────────────────
  Widget _buildPredictionCard(MachinePulse pulse, Color accent) {
    final willMeet = pulse.willMeetTarget;
    final projectedColor =
        willMeet ? const Color(0xFF4ADE80) : const Color(0xFFF87171);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ML PROJECTION · EOD',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pulse.projectedEodUnits.toStringAsFixed(0),
                    style: TextStyle(
                      color: projectedColor,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -2,
                    ),
                  ),
                  const Text(
                    'units projected',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '500',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const Text(
                    'target',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar: projected vs target
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                end: (pulse.projectedEodUnits / 500).clamp(0, 1.2),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(projectedColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            willMeet
                ? '▲ On track to meet daily target'
                : '▼ Projected to miss target by '
                    '${(500 - pulse.projectedEodUnits).toStringAsFixed(0)} units',
            style: TextStyle(
              color: projectedColor.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom bar ───────────────────────────────────────────────────────────
  Widget _buildBottomBar(MachinePulse? pulse, Color accent) {
    final ts = pulse?.timestamp;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ts != null ? 'Last pulse: ${_formatTime(ts)}' : 'No data',
            style: const TextStyle(color: Colors.white24, fontSize: 11),
          ),
          Text(
            'SMV 0.5 · TARGET 500',
            style: const TextStyle(
                color: Colors.white24, fontSize: 11, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }
}

// ─── Private helper ───────────────────────────────────────────────────────────
class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
  });
  final String label;
  final String value;
  final String unit;
  final Color accent;
}
