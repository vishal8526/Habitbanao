import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/habit_model.dart';
import '../providers/timer_provider.dart';
import '../providers/habit_provider.dart';
import '../utils/helpers.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> {
  bool _linked = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(timerProvider);
    final habits =
        ref
            .watch(habitProvider)
            .activeHabits
            .where((h) => h.type == HabitType.duration)
            .toList();
    final theme = Theme.of(context);

    if (t.status == TimerStatus.finished &&
        t.linkedHabitId != null &&
        !_linked) {
      _linked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(habitProvider.notifier)
            .setDuration(
              t.linkedHabitId!,
              DateHelper.today(),
              t.totalSeconds ~/ 60,
            );
      });
    }
    if (t.status != TimerStatus.finished) _linked = false;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Timer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (habits.isNotEmpty)
              DropdownButtonFormField<String?>(
                initialValue: t.linkedHabitId,
                decoration: const InputDecoration(
                  labelText: 'Link to habit',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...habits.map(
                    (h) => DropdownMenuItem(
                      value: h.id,
                      child: Text('${h.emoji} ${h.name}'),
                    ),
                  ),
                ],
                onChanged:
                    (v) => ref.read(timerProvider.notifier).setLinkedHabit(v),
              ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: _TP(
                      progress: t.progress,
                      color: theme.colorScheme.primary,
                      bg: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DurationHelper.formatTimer(t.remainingSeconds),
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (t.status == TimerStatus.finished)
                            Text(
                              'Done! 🎉',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (t.status == TimerStatus.idle)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children:
                    [5, 10, 15, 25, 30, 60]
                        .map(
                          (m) => OutlinedButton(
                            onPressed:
                                () => ref
                                    .read(timerProvider.notifier)
                                    .setDuration(m),
                            child: Text('${m}m'),
                          ),
                        )
                        .toList(),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (t.status == TimerStatus.idle ||
                    t.status == TimerStatus.finished)
                  FilledButton.icon(
                    onPressed: () {
                      if (t.status == TimerStatus.finished) {
                        ref.read(timerProvider.notifier).reset();
                      }
                      ref.read(timerProvider.notifier).start();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 56),
                    ),
                  ),
                if (t.status == TimerStatus.running) ...[
                  FilledButton.icon(
                    onPressed: () => ref.read(timerProvider.notifier).pause(),
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 56),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(timerProvider.notifier).stop(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ],
                if (t.status == TimerStatus.paused) ...[
                  FilledButton.icon(
                    onPressed: () => ref.read(timerProvider.notifier).resume(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 56),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(timerProvider.notifier).stop(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sessions today: ${t.sessionsToday}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TP extends CustomPainter {
  final double progress;
  final Color color, bg;
  _TP({required this.progress, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 - 8;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = bg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TP old) => old.progress != progress;
}
