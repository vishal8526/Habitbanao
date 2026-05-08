import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/habit_templates.dart';
import '../../data/models/habit_model.dart';
import '../../providers/habit_provider.dart';

class CreateHabitScreen extends ConsumerStatefulWidget {
  final String? habitId;
  final int? templateIndex;
  const CreateHabitScreen({super.key, this.habitId, this.templateIndex});
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

  String _emoji = '⭐';
  int _colorValue = 0xFF42A5F5;
  HabitType _type = HabitType.boolean;
  FrequencyType _frequency = FrequencyType.daily;
  List<int> _scheduledDays = [1, 2, 3, 4, 5, 6, 7];
  String _category = 'Health';
  TimeOfDayCategory _timeOfDay = TimeOfDayCategory.anytime;
  bool _isEditing = false;
  HabitModel? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.habitId != null) {
      _existing = ref.read(habitRepositoryProvider).getHabit(widget.habitId!);
      if (_existing != null) {
        _isEditing = true;
        _nameController.text = _existing!.name;
        _descController.text = _existing!.description;
        _emoji = _existing!.emoji;
        _colorValue = _existing!.colorValue;
        _type = _existing!.type;
        _frequency = _existing!.frequency;
        _scheduledDays = List.from(_existing!.scheduledDays);
        _targetCountController.text = '${_existing!.targetCount}';
        _targetValueController.text = '${_existing!.targetValue}';
        _unitController.text = _existing!.unit;
        _durationController.text = '${_existing!.targetDurationMinutes}';
        _category = _existing!.categoryId;
        _timeOfDay = _existing!.timeOfDay;
      }
    } else if (widget.templateIndex != null) {
      final t = HabitTemplates.all[widget.templateIndex!];
      _nameController.text = t.name;
      _emoji = t.emoji;
      _colorValue = t.colorValue;
      _type = t.type;
      _targetCountController.text = '${t.targetCount}';
      _targetValueController.text = '${t.targetValue}';
      _unitController.text = t.unit;
      _durationController.text = '${t.targetDurationMinutes}';
      _category = t.category;
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

    final habit =
        _isEditing
            ? _existing!.copyWith(
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
              targetDurationMinutes:
                  int.tryParse(_durationController.text) ?? 0,
              categoryId: _category,
              timeOfDay: _timeOfDay,
            )
            : HabitModel(
              id: const Uuid().v4(),
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
              targetDurationMinutes:
                  int.tryParse(_durationController.text) ?? 0,
              categoryId: _category,
              timeOfDay: _timeOfDay,
            );

    if (_isEditing) {
      await ref.read(habitsProvider.notifier).updateHabit(habit);
    } else {
      await ref.read(habitsProvider.notifier).addHabit(habit);
    }

    setState(() => _saving = false);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'Create Habit'),
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
          padding: const EdgeInsets.all(20),
          children: [
            // Emoji and color row
            Row(
              children: [
                GestureDetector(
                  onTap: _showEmojiPicker,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Color(_colorValue).withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(_emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Habit Name'),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Color picker
            Text('Color', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  AppConstants.habitColors.map((c) {
                    final selected = c.value == _colorValue;
                    return GestureDetector(
                      onTap: () => setState(() => _colorValue = c.value),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border:
                              selected
                                  ? Border.all(
                                    color: theme.colorScheme.onSurface,
                                    width: 3,
                                  )
                                  : null,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),

            // Tracking type
            Text('Tracking Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _typeChip('Yes/No', HabitType.boolean, '✅'),
                _typeChip('Count', HabitType.count, '🔢'),
                _typeChip('Duration', HabitType.duration, '⏱️'),
                _typeChip('Measurable', HabitType.measurable, '📏'),
              ],
            ),
            const SizedBox(height: 16),

            // Target based on type
            if (_type == HabitType.count) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetCountController,
                      decoration: const InputDecoration(
                        labelText: 'Target Count',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit (e.g. glasses)',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_type == HabitType.duration) ...[
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Target Duration (minutes)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            if (_type == HabitType.measurable) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetValueController,
                      decoration: const InputDecoration(
                        labelText: 'Target Value',
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
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Frequency
            Text('Frequency', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<FrequencyType>(
              segments: const [
                ButtonSegment(value: FrequencyType.daily, label: Text('Daily')),
                ButtonSegment(
                  value: FrequencyType.weekly,
                  label: Text('Weekly'),
                ),
                ButtonSegment(
                  value: FrequencyType.custom,
                  label: Text('Custom'),
                ),
              ],
              selected: {_frequency},
              onSelectionChanged: (v) => setState(() => _frequency = v.first),
            ),
            if (_frequency == FrequencyType.custom) ...[
              const SizedBox(height: 12),
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
                      final selected = _scheduledDays.contains(day);
                      return FilterChip(
                        label: Text(e.value),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _scheduledDays.add(day);
                            } else {
                              _scheduledDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // Time of day
            Text('Time of Day', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  TimeOfDayCategory.values
                      .map(
                        (t) => ChoiceChip(
                          label: Text(_timeLabel(t)),
                          selected: _timeOfDay == t,
                          onSelected: (_) => setState(() => _timeOfDay = t),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 20),

            // Category
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  AppConstants.categories
                      .asMap()
                      .entries
                      .map(
                        (e) => ChoiceChip(
                          label: Text(
                            '${AppConstants.categoryEmojis[e.key]} ${e.value}',
                          ),
                          selected: _category == e.value,
                          onSelected:
                              (_) => setState(() => _category = e.value),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 32),

            // Save
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child:
                    _saving
                        ? const CircularProgressIndicator.adaptive()
                        : Text(_isEditing ? 'Update Habit' : 'Create Habit'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, HabitType type, String emoji) {
    final selected = _type == type;
    return ChoiceChip(
      label: Text('$emoji $label'),
      selected: selected,
      onSelected: (_) => setState(() => _type = type),
    );
  }

  String _timeLabel(TimeOfDayCategory t) {
    switch (t) {
      case TimeOfDayCategory.morning:
        return '🌅 Morning';
      case TimeOfDayCategory.afternoon:
        return '☀️ Afternoon';
      case TimeOfDayCategory.evening:
        return '🌙 Evening';
      case TimeOfDayCategory.anytime:
        return '⭐ Anytime';
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (ctx, scroll) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Pick an Emoji',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                            ),
                        itemCount: AppConstants.emojis.length,
                        itemBuilder:
                            (ctx, i) => GestureDetector(
                              onTap: () {
                                setState(() => _emoji = AppConstants.emojis[i]);
                                Navigator.pop(ctx);
                              },
                              child: Center(
                                child: Text(
                                  AppConstants.emojis[i],
                                  style: const TextStyle(fontSize: 24),
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
