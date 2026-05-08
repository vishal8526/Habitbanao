import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/journal_provider.dart';
import '../utils/helpers.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _tc = TextEditingController();
  final _sc = TextEditingController();
  String _search = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _tc.dispose();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalProvider);
    final theme = Theme.of(context);
    final filtered =
        _search.isEmpty
            ? entries
            : ref.read(journalProvider.notifier).search(_search);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tc,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Write something...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () async {
                    if (_tc.text.trim().isNotEmpty) {
                      await ref
                          .read(journalProvider.notifier)
                          .add(_tc.text.trim());
                      _tc.clear();
                    }
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _sc,
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  setState(() => _search = v);
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                filtered.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📓', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text(
                            'No entries yet',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final e = filtered[i];
                        return Dismissible(
                          key: ValueKey(e.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red.withAlpha(51),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          onDismissed:
                              (_) => ref
                                  .read(journalProvider.notifier)
                                  .remove(e.id),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateHelper.formatDate(e.date),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e.text,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (e.tags.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                        spacing: 4,
                                        children:
                                            e.tags
                                                .map(
                                                  (t) => Chip(
                                                    label: Text(
                                                      t,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                )
                                                .toList(),
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
}
