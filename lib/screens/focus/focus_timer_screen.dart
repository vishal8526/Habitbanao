import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../providers/habit_provider.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});
  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  String? _linkedHabitId;
  int _sessionsToday = 0;
  int _totalFocusToday = 0;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _start() {
    WakelockPlus.enable();
    _animController.repeat();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        setState(() => _isRunning = false);
        WakelockPlus.disable();
        _sessionsToday++;
        _totalFocusToday += _totalSeconds ~/ 60;
        _onTimerComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    _animController.stop();
    setState(() => _isRunning = false);
    WakelockPlus.disable();
  }

  void _reset() {
    _timer?.cancel();
    _animController.stop();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
    WakelockPlus.disable();
  }

  void _setDuration(int minutes) {
    _timer?.cancel();
    setState(() {
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
    });
  }

  void _onTimerComplete() {
    // Auto-complete linked habit
    if (_linkedHabitId != null) {
      final habit = ref.read(habitRepositoryProvider).getHabit(_linkedHabitId!);
      if (habit != null) {
        ref
            .read(habitEntriesProvider.notifier)
            .setDuration(habit, _totalSeconds ~/ 60);
      }
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('🎉 Focus session complete!')));
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider);
    final activeHabits = habits.activeHabits;
    final progress =
        _totalSeconds > 0
            ? (_totalSeconds - _remainingSeconds) / _totalSeconds
            : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Timer')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Linked habit
            DropdownButtonFormField<String?>(
              initialValue: _linkedHabitId,
              decoration: const InputDecoration(
                labelText: 'Link to Habit (optional)',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...activeHabits.map(
                  (h) => DropdownMenuItem(
                    value: h.id,
                    child: Text('${h.emoji} ${h.name}'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _linkedHabitId = v),
            ),
            const Spacer(),

            // Timer ring
            SizedBox(
              width: 250,
              height: 250,
              child: AnimatedBuilder(
                animation: _animController,
                builder:
                    (context, child) => CustomPaint(
                      painter: _TimerPainter(
                        progress: progress,
                        color: theme.colorScheme.primary,
                        bgColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: Center(
                        child: Text(
                          _formatTime(_remainingSeconds),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Preset buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [5, 10, 15, 25, 30, 60]
                      .map(
                        (m) => ActionChip(
                          label: Text('${m}m'),
                          onPressed: _isRunning ? null : () => _setDuration(m),
                          backgroundColor:
                              _totalSeconds == m * 60
                                  ? theme.colorScheme.primaryContainer
                                  : null,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: _reset,
                  icon: const Icon(Icons.stop),
                  iconSize: 32,
                ),
                const SizedBox(width: 20),
                IconButton.filled(
                  onPressed: _isRunning ? _pause : _start,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  iconSize: 48,
                ),
                const SizedBox(width: 20),
                IconButton.filledTonal(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  iconSize: 32,
                ),
              ],
            ),
            const Spacer(),

            // Session info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '$_sessionsToday',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Sessions', style: theme.textTheme.labelSmall),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$_totalFocusToday min',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Total Focus', style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  _TimerPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter old) => old.progress != progress;
}
