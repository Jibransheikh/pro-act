import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/badge.dart';

class VaultTab extends StatelessWidget {
  const VaultTab({super.key});

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
                  Text('THE VAULT', style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  const Text('Your legacy.', style: AppTextStyles.titleLarge),
                ],
              ),
            ),
          ),

          // Badge Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = dummyBadges[index];
                  return _BadgeCard(badge: badge);
                },
                childCount: dummyBadges.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Badge badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badge.isUnlocked ? AppColors.surface : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.isUnlocked ? AppColors.accent.withOpacity(0.3) : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.icon,
            style: TextStyle(
              fontSize: 32,
              color: badge.isUnlocked ? null : Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: badge.isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 9,
              color: badge.isUnlocked ? AppColors.textSecondary : AppColors.textMuted,
            ),
          ),
          if (!badge.isUnlocked) ...[
            const SizedBox(height: 8),
            const Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
          ],
        ],
      ),
    );
  }
}