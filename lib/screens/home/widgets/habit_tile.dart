import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/models/habit_entry_model.dart';
import '../../../providers/habit_provider.dart';

class HabitTile extends ConsumerStatefulWidget {
  final HabitModel habit;
  final HabitEntryModel? entry;
  const HabitTile({super.key, required this.habit, this.entry});
  @override
  ConsumerState<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends ConsumerState<HabitTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    _bounceController.forward().then((_) => _bounceController.reverse());

    switch (widget.habit.type) {
      case HabitType.boolean:
        ref.read(habitEntriesProvider.notifier).toggleBoolean(widget.habit);
        break;
      case HabitType.count:
        ref.read(habitEntriesProvider.notifier).incrementCount(widget.habit);
        break;
      case HabitType.duration:
        _showDurationDialog();
        break;
      case HabitType.measurable:
        _showMeasurableDialog();
        break;
    }
  }

  void _onLongPress() {
    if (widget.habit.type == HabitType.count) {
      _showCountDialog();
    } else {
      context.push('/habit/${widget.habit.id}');
    }
  }

  void _showCountDialog() {
    final controller = TextEditingController(
      text: '${widget.entry?.countValue ?? 0}',
    );
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Set ${widget.habit.name}'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffix: Text(
                  '/ ${widget.habit.targetCount} ${widget.habit.unit}',
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final val = int.tryParse(controller.text) ?? 0;
                  ref
                      .read(habitEntriesProvider.notifier)
                      .setCount(widget.habit, val);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showDurationDialog() {
    final controller = TextEditingController(
      text: '${widget.entry?.durationMinutes ?? 0}',
    );
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('${widget.habit.name} Duration'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffix: Text('/ ${widget.habit.targetDurationMinutes} min'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final val = int.tryParse(controller.text) ?? 0;
                  ref
                      .read(habitEntriesProvider.notifier)
                      .setDuration(widget.habit, val);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showMeasurableDialog() {
    final controller = TextEditingController(
      text: '${widget.entry?.measuredValue ?? 0}',
    );
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(widget.habit.name),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                suffix: Text(
                  '/ ${widget.habit.targetValue} ${widget.habit.unit}',
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final val = double.tryParse(controller.text) ?? 0;
                  ref
                      .read(habitEntriesProvider.notifier)
                      .setMeasurable(widget.habit, val);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = widget.habit;
    final entry = widget.entry;
    final isCompleted = entry?.isCompleted ?? false;
    final color = Color(habit.colorValue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: _onTap,
        onLongPress: _onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? color.withAlpha(38)
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted ? color.withAlpha(128) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (_subtitle != null)
                      Text(
                        _subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              _buildTrailing(theme, color),
            ],
          ),
        ),
      ),
    );
  }

  String? get _subtitle {
    final entry = widget.entry;
    switch (widget.habit.type) {
      case HabitType.boolean:
        return null;
      case HabitType.count:
        return '${entry?.countValue ?? 0} / ${widget.habit.targetCount} ${widget.habit.unit}';
      case HabitType.duration:
        return '${entry?.durationMinutes ?? 0} / ${widget.habit.targetDurationMinutes} min';
      case HabitType.measurable:
        return '${entry?.measuredValue ?? 0} / ${widget.habit.targetValue} ${widget.habit.unit}';
    }
  }

  Widget _buildTrailing(ThemeData theme, Color color) {
    final entry = widget.entry;
    final isCompleted = entry?.isCompleted ?? false;

    switch (widget.habit.type) {
      case HabitType.boolean:
        return ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? color : Colors.transparent,
              border: Border.all(
                color: isCompleted ? color : theme.colorScheme.outline,
                width: 2,
              ),
            ),
            child:
                isCompleted
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
          ),
        );
      case HabitType.count:
        final progress =
            widget.habit.targetCount > 0
                ? (entry?.countValue ?? 0) / widget.habit.targetCount
                : 0.0;
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.clamp(0, 1).toDouble(),
                strokeWidth: 3,
                color: color,
                backgroundColor: color.withAlpha(51),
              ),
              Text(
                '${entry?.countValue ?? 0}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case HabitType.duration:
        final progress =
            widget.habit.targetDurationMinutes > 0
                ? (entry?.durationMinutes ?? 0) /
                    widget.habit.targetDurationMinutes
                : 0.0;
        return SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              minHeight: 8,
              color: color,
              backgroundColor: color.withAlpha(51),
            ),
          ),
        );
      case HabitType.measurable:
        return Text(
          '${entry?.measuredValue ?? 0}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }
}
