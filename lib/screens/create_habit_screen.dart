import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../utils/constants.dart';

class CreateHabitScreen extends ConsumerStatefulWidget {
  final String? habitId;
  final Map<String, dynamic>? template;
  const CreateHabitScreen({super.key, this.habitId, this.template});

  @override
  ConsumerState<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _targetCountController = TextEditingController(text: '1');
  final _targetValueController = TextEditingController(text: '0');
  final _unitController = TextEditingController();
  final _durationController = TextEditingController(text: '0');

  String _emoji = '✅';
  int _colorValue = 0xFF4CAF50;
  HabitType _type = HabitType.boolean;
  FrequencyType _frequency = FrequencyType.daily;
  List<int> _scheduledDays = [1, 2, 3, 4, 5, 6, 7];
  TimeOfDayCategory _timeOfDay = TimeOfDayCategory.anytime;
  String _categoryId = 'General';
  bool _isEdit = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.habitId != null) {
      _isEdit = true;
      final box = Hive.box<HabitModel>('habits');
      final habit = box.get(widget.habitId);
      if (habit != null) {
        _nameController.text = habit.name;
        _descController.text = habit.description;
        _emoji = habit.emoji;
        _colorValue = habit.colorValue;
        _type = habit.type;
        _frequency = habit.frequency;
        _scheduledDays = List.from(habit.scheduledDays);
        _targetCountController.text = habit.targetCount.toString();
        _targetValueController.text = habit.targetValue.toString();
        _unitController.text = habit.unit;
        _durationController.text = habit.targetDurationMinutes.toString();
        _timeOfDay = habit.timeOfDay;
        _categoryId = habit.categoryId;
      }
    } else if (widget.template != null) {
      final t = widget.template!;
      _nameController.text = (t['name'] as String?) ?? '';
      _emoji = (t['emoji'] as String?) ?? '✅';
      _type = (t['type'] as HabitType?) ?? HabitType.boolean;
      _targetCountController.text =
          ((t['targetCount'] as int?) ?? 1).toString();
      _targetValueController.text =
          ((t['targetValue'] as double?) ?? 0).toString();
      _unitController.text = (t['unit'] as String?) ?? '';
      _durationController.text =
          ((t['targetDurationMinutes'] as int?) ?? 0).toString();
      _categoryId = (t['category'] as String?) ?? 'General';
      _descController.text = (t['description'] as String?) ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetCountController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final habit = HabitModel(
      id: widget.habitId ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      emoji: _emoji,
      colorValue: _colorValue,
      type: _type,
      frequency: _frequency,
      scheduledDays: _scheduledDays,
      targetCount: int.tryParse(_targetCountController.text) ?? 1,
      targetValue: double.tryParse(_targetValueController.text) ?? 0,
      unit: _unitController.text.trim(),
      targetDurationMinutes: int.tryParse(_durationController.text) ?? 0,
      timeOfDay: _timeOfDay,
      categoryId: _categoryId,
    );

    if (_isEdit) {
      final old = Hive.box<HabitModel>('habits').get(widget.habitId);
      if (old != null) {
        habit.currentStreak = old.currentStreak;
        habit.bestStreak = old.bestStreak;
        habit.sortOrder = old.sortOrder;
        habit.createdAt = old.createdAt;
        habit.startDate = old.startDate;
      }
      await ref.read(habitProvider.notifier).updateHabit(habit);
    } else {
      await ref.read(habitProvider.notifier).addHabit(habit);
    }

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Habit' : 'Create Habit'),
        actions: [
          TextButton(
            onPressed: () => context.push('/templates'),
            child: const Text('Templates'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showEmojiPicker,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(_colorValue).withAlpha(38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(_emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Habit Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Text('Color', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  AppConstants.habitColors
                      .map(
                        (c) => GestureDetector(
                          onTap: () => setState(() => _colorValue = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border:
                                  _colorValue == c
                                      ? Border.all(
                                        color: theme.colorScheme.onSurface,
                                        width: 3,
                                      )
                                      : null,
                            ),
                            child:
                                _colorValue == c
                                    ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                    : null,
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 20),
            Text('Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 16),
            if (_type == HabitType.count) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetCountController,
                      decoration: const InputDecoration(
                        labelText: 'Target Count',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_type == HabitType.duration) ...[
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Target (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
            if (_type == HabitType.measurable) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetValueController,
                      decoration: const InputDecoration(
                        labelText: 'Target Value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text('Frequency', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<FrequencyType>(
              segments: const [
                ButtonSegment(value: FrequencyType.daily, label: Text('Daily')),
                ButtonSegment(
                  value: FrequencyType.custom,
                  label: Text('Custom'),
                ),
              ],
              selected: {
                _frequency == FrequencyType.daily
                    ? FrequencyType.daily
                    : FrequencyType.custom,
              },
              onSelectionChanged:
                  (s) => setState(() {
                    _frequency = s.first;
                    if (_frequency == FrequencyType.daily) {
                      _scheduledDays = [1, 2, 3, 4, 5, 6, 7];
                    }
                  }),
            ),
            if (_frequency == FrequencyType.custom) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children:
                    [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ].asMap().entries.map((e) {
                      final day = e.key + 1;
                      return FilterChip(
                        label: Text(e.value),
                        selected: _scheduledDays.contains(day),
                        onSelected:
                            (v) => setState(() {
                              if (v) {
                                _scheduledDays.add(day);
                              } else {
                                _scheduledDays.remove(day);
                              }
                            }),
                      );
                    }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text('Time of Day', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TimeOfDayCategory>(
              segments: const [
                ButtonSegment(
                  value: TimeOfDayCategory.morning,
                  label: Text('🌅'),
                ),
                ButtonSegment(
                  value: TimeOfDayCategory.afternoon,
                  label: Text('☀️'),
                ),
                ButtonSegment(
                  value: TimeOfDayCategory.evening,
                  label: Text('🌙'),
                ),
                ButtonSegment(
                  value: TimeOfDayCategory.anytime,
                  label: Text('⏰'),
                ),
              ],
              selected: {_timeOfDay},
              onSelectionChanged: (s) => setState(() => _timeOfDay = s.first),
            ),
            const SizedBox(height: 16),
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  AppConstants.categories
                      .map(
                        (c) => ChoiceChip(
                          label: Text(
                            '${AppConstants.categoryEmojis[c] ?? ''} $c',
                          ),
                          selected: _categoryId == c,
                          onSelected: (v) {
                            if (v) setState(() => _categoryId = c);
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(_isEdit ? 'Update Habit' : 'Create Habit'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = [
      (HabitType.boolean, 'Yes/No', Icons.check_circle_outline),
      (HabitType.count, 'Count', Icons.add_circle_outline),
      (HabitType.duration, 'Duration', Icons.timer_outlined),
      (HabitType.measurable, 'Measure', Icons.straighten),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children:
          types.map((t) {
            final selected = _type == t.$1;
            return GestureDetector(
              onTap: () => setState(() => _type = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        selected
                            ? Color(_colorValue)
                            : Theme.of(context).colorScheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                  color: selected ? Color(_colorValue).withAlpha(25) : null,
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t.$3,
                      color: selected ? Color(_colorValue) : null,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.$2,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.bold : null,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(16),
            height: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick an emoji',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                        ),
                    itemCount: AppConstants.commonEmojis.length,
                    itemBuilder:
                        (_, i) => GestureDetector(
                          onTap: () {
                            setState(
                              () => _emoji = AppConstants.commonEmojis[i],
                            );
                            Navigator.pop(context);
                          },
                          child: Center(
                            child: Text(
                              AppConstants.commonEmojis[i],
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
