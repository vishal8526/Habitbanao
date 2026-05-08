import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

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
  int _weekStart = 1;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final name =
        _nameController.text.trim().isEmpty
            ? 'User'
            : _nameController.text.trim();
    final profileBox = Hive.box<UserProfile>('user_profile');
    final profile = UserProfile(name: name, weekStartDay: _weekStart);
    profileBox.put('profile', profile);

    const uuid = Uuid();
    for (final idx in _selectedTemplates) {
      if (idx < HabitTemplate.all.length) {
        final t = HabitTemplate.all[idx];
        final habit = HabitModel(
          id: uuid.v4(),
          name: t.name,
          emoji: t.emoji,
          type: t.type,
          targetCount: t.targetCount,
          targetValue: t.targetValue,
          unit: t.unit,
          targetDurationMinutes: t.targetDurationMinutes,
          categoryId: t.category,
          description: t.description,
          sortOrder: _selectedTemplates.toList().indexOf(idx),
        );
        await ref.read(habitProvider.notifier).addHabit(habit);
      }
    }

    final settingsBox = Hive.box('settings');
    await settingsBox.put('onboarding_complete', true);

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(_currentPage == 3 ? 'Done' : 'Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildInfoPage(
                    icon: Icons.track_changes,
                    title: 'Track Your Habits',
                    subtitle:
                        'Build positive routines and track your daily progress with ease.',
                    color: theme.colorScheme.primary,
                  ),
                  _buildInfoPage(
                    icon: Icons.local_fire_department,
                    title: 'Build Streaks 🔥',
                    subtitle:
                        'Stay consistent and watch your streaks grow day by day.',
                    color: Colors.orange,
                  ),
                  _buildInfoPage(
                    icon: Icons.emoji_events,
                    title: 'Achieve Goals 🏆',
                    subtitle:
                        'Earn XP, unlock achievements, and level up your life!',
                    color: Colors.amber,
                  ),
                  _buildSetupPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          _currentPage == i
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(_currentPage == 3 ? 'Get Started!' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPage({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(icon, size: 120, color: color),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's set up your profile",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          Text(
            'Week starts on:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('Monday')),
              ButtonSegment(value: 7, label: Text('Sunday')),
            ],
            selected: {_weekStart},
            onSelectionChanged: (s) => setState(() => _weekStart = s.first),
          ),
          const SizedBox(height: 24),
          Text(
            'Pick starter habits:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(HabitTemplate.all.length.clamp(0, 12), (i) {
              final t = HabitTemplate.all[i];
              return FilterChip(
                label: Text('${t.emoji} ${t.name}'),
                selected: _selectedTemplates.contains(i),
                onSelected:
                    (v) => setState(() {
                      v
                          ? _selectedTemplates.add(i)
                          : _selectedTemplates.remove(i);
                    }),
              );
            }),
          ),
          const SizedBox(height: 24),
          Text('Theme Color:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                AppConstants.accentColors.map((c) {
                  final sel =
                      ref.watch(themeProvider).accentColor.value == c.value;
                  return GestureDetector(
                    onTap:
                        () =>
                            ref.read(themeProvider.notifier).setAccentColor(c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border:
                            sel
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                        boxShadow:
                            sel
                                ? [
                                  BoxShadow(
                                    color: c.withAlpha(128),
                                    blurRadius: 8,
                                  ),
                                ]
                                : null,
                      ),
                      child:
                          sel
                              ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
