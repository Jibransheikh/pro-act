import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/achievement.dart';

class CircleTab extends StatelessWidget {
  const CircleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACHIEVEMENTS', style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  const Text('Brothers winning.', style: AppTextStyles.titleLarge),
                ],
              ),
            ),
          ),

          // Achievement List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final achievement = dummyAchievements[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: _AchievementCard(achievement: achievement),
                );
              },
              childCount: dummyAchievements.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(achievement.brotherAvatar),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.brotherName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _getTimeAgo(achievement.timestamp),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                achievement.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              achievement.achievementTitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.achievementDescription,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _InteractionButton(icon: Icons.favorite_border, label: 'RESPECT'),
              const SizedBox(width: 16),
              _InteractionButton(icon: Icons.chat_bubble_outline, label: 'SALUTE'),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InteractionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}