import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/habit_provider.dart';
import '../../providers/settings_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileRepositoryProvider).getProfile();
    final achievements = ref.watch(achievementRepositoryProvider).getAll();
    final unlocked = achievements.where((a) => a.isUnlocked).length;

    // XP progress to next level
    final currentThreshold = AppConstants.levelXPThresholds[profile.level] ?? 0;
    final nextLevel = (profile.level + 1).clamp(1, 30);
    final nextThreshold =
        AppConstants.levelXPThresholds[nextLevel] ?? currentThreshold;
    final xpProgress =
        nextThreshold > currentThreshold
            ? (profile.totalXP - currentThreshold) /
                (nextThreshold - currentThreshold)
            : 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Level card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Level ${profile.level}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppConstants.levelNames[profile.level] ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: xpProgress.clamp(0, 1).toDouble(),
                      minHeight: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${profile.totalXP} / $nextThreshold XP',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$unlocked / ${achievements.length} achievements unlocked',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Achievements grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              return Card(
                color:
                    a.isUnlocked
                        ? theme.colorScheme.primaryContainer.withAlpha(128)
                        : null,
                child: InkWell(
                  onTap: () => _showAchievementDetail(context, a, theme),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              a.iconEmoji,
                              style: TextStyle(
                                fontSize: 32,
                                color: a.isUnlocked ? null : Colors.grey,
                              ),
                            ),
                            if (!a.isUnlocked)
                              const Icon(
                                Icons.lock,
                                size: 16,
                                color: Colors.grey,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.title,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '+${a.xpReward} XP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showAchievementDetail(
    BuildContext context,
    dynamic a,
    ThemeData theme,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                Text(a.iconEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(child: Text(a.title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.description),
                const SizedBox(height: 8),
                Text(
                  'Reward: +${a.xpReward} XP',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                if (a.isUnlocked && a.unlockedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Unlocked: ${a.unlockedAt.day}/${a.unlockedAt.month}/${a.unlockedAt.year}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
