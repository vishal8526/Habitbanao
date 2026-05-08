import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/habit_templates.dart';
import '../../data/models/habit_model.dart';
import '../../main.dart';
import '../../providers/habit_provider.dart';
import '../../providers/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();
  final _selectedTemplates = <int>{};
  int _weekStartDay = 1;

  final _pages = const [
    _OnboardingPage(
      emoji: '📋',
      title: 'Track Your Habits',
      subtitle:
          'Build and track daily habits that help you become the best version of yourself.',
    ),
    _OnboardingPage(
      emoji: '🔥',
      title: 'Build Streaks',
      subtitle:
          'Stay consistent and watch your streaks grow. Never break the chain!',
    ),
    _OnboardingPage(
      emoji: '🏆',
      title: 'Achieve Goals',
      subtitle:
          'Unlock achievements, earn XP, and level up as you build better habits.',
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final name =
        _nameController.text.trim().isEmpty
            ? 'User'
            : _nameController.text.trim();
    final profileRepo = ref.read(profileRepositoryProvider);
    final profile = profileRepo.getProfile();
    profile.name = name;
    profile.weekStartDay = _weekStartDay;
    await profileRepo.saveProfile(profile);

    // Init achievements
    await ref.read(achievementRepositoryProvider).initializeAchievements();

    // Create selected habits
    final uuid = const Uuid();
    for (final i in _selectedTemplates) {
      final t = HabitTemplates.all[i];
      final habit = HabitModel(
        id: uuid.v4(),
        name: t.name,
        emoji: t.emoji,
        colorValue: t.colorValue,
        type: t.type,
        targetCount: t.targetCount,
        targetValue: t.targetValue,
        unit: t.unit,
        targetDurationMinutes: t.targetDurationMinutes,
        categoryId: t.category,
        sortOrder: i,
      );
      await ref.read(habitsProvider.notifier).addHabit(habit);
    }

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('first_launch', false);

    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  if (_currentPage < 3) {
                    _pageController.animateToPage(
                      3,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _complete();
                  }
                },
                child: Text(_currentPage < 3 ? 'Skip' : ''),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  ..._pages.map((p) => _buildInfoPage(p, theme)),
                  _buildSetupPage(theme),
                ],
              ),
            ),
            // Dot indicators
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          _currentPage == i
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withAlpha(77),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Next/Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    if (_currentPage < 3) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _complete();
                    }
                  },
                  child: Text(
                    _currentPage < 3 ? 'Next' : 'Get Started',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPage(_OnboardingPage page, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(page.emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Up Your Profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          Text('Week starts on', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('Monday')),
              ButtonSegment(value: 7, label: Text('Sunday')),
            ],
            selected: {_weekStartDay},
            onSelectionChanged: (v) => setState(() => _weekStartDay = v.first),
          ),
          const SizedBox(height: 24),
          Text(
            'Pick up to 3 starter habits',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(HabitTemplates.all.length.clamp(0, 15), (
              i,
            ) {
              final t = HabitTemplates.all[i];
              final selected = _selectedTemplates.contains(i);
              return FilterChip(
                selected: selected,
                label: Text('${t.emoji} ${t.name}'),
                onSelected: (v) {
                  setState(() {
                    if (v && _selectedTemplates.length < 3) {
                      _selectedTemplates.add(i);
                    } else {
                      _selectedTemplates.remove(i);
                    }
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}
