import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/habit_model.dart';
import '../utils/constants.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});
  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  String _cat = 'All';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final cats = ['All', ...AppConstants.categories];
    var templates = HabitTemplate.all.toList();
    if (_cat != 'All') {
      templates = templates.where((t) => t.category == _cat).toList();
    }
    if (_search.isNotEmpty) {
      templates =
          templates
              .where(
                (t) => t.name.toLowerCase().contains(_search.toLowerCase()),
              )
              .toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children:
                  cats
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(c),
                            selected: _cat == c,
                            onSelected: (_) => setState(() => _cat = c),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: templates.length,
              itemBuilder: (_, i) {
                final t = templates[i];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap:
                        () => context.push(
                          '/create-habit',
                          extra: <String, dynamic>{
                            'name': t.name,
                            'emoji': t.emoji,
                            'category': t.category,
                            'type': t.type,
                            'targetCount': t.targetCount,
                            'targetValue': t.targetValue,
                            'unit': t.unit,
                            'targetDurationMinutes': t.targetDurationMinutes,
                            'description': t.description,
                          },
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text(
                            t.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _tl(t),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _tl(HabitTemplate t) => switch (t.type) {
    HabitType.boolean => 'Yes/No',
    HabitType.count => '${t.targetCount} ${t.unit}',
    HabitType.duration => '${t.targetDurationMinutes} min',
    HabitType.measurable => '${t.targetValue} ${t.unit}',
  };
}
