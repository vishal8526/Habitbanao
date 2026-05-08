import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/journal_repository.dart';

final journalRepositoryProvider = Provider((ref) => JournalRepository());

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _textController = TextEditingController();
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(journalRepositoryProvider);
    final entries = _search.isEmpty ? repo.getAll() : repo.search(_search);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: Column(
        children: [
          // Write entry
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Write something...',
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () async {
                    if (_textController.text.trim().isNotEmpty) {
                      await repo.add(_textController.text.trim());
                      _textController.clear();
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search journal...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                entries.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📓', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text(
                            'No journal entries yet',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        return Dismissible(
                          key: ValueKey(e.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red.withAlpha(51),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          onDismissed: (_) {
                            repo.delete(e.id);
                            setState(() {});
                          },
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (e.moodEmoji != null)
                                        Text(
                                          e.moodEmoji!,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      if (e.moodEmoji != null)
                                        const SizedBox(width: 8),
                                      Text(
                                        '${e.date.day}/${e.date.month}/${e.date.year}  ${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    e.text,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (e.tags.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
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
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  ],
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
