import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/brother.dart';

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

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
                  Text('THE CIRCLE', style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  const Text('Brothers in arms.', style: AppTextStyles.titleLarge),
                ],
              ),
            ),
          ),

          // Online brothers section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('ONLINE NOW', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // List of brothers
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final brother = dummyBrothers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: BrotherCard(brother: brother),
                );
              },
              childCount: dummyBrothers.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class BrotherCard extends StatefulWidget {
  final Brother brother;
  const BrotherCard({super.key, required this.brother});

  @override
  State<BrotherCard> createState() => _BrotherCardState();
}

class _BrotherCardState extends State<BrotherCard> with SingleTickerProviderStateMixin {
  late AnimationController _nudgeController;
  late Animation<double> _nudgeScale;
  bool _isNudged = false;

  @override
  void initState() {
    super.initState();
    _nudgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _nudgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _nudgeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _nudgeController.dispose();
    super.dispose();
  }

  void _handleNudge() {
    _nudgeController.forward(from: 0.0);
    setState(() => _isNudged = true);
    
    // Reset "nudged" state after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isNudged = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You nudged ${widget.brother.name}.'),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.brother.isOnline ? AppColors.accent.withOpacity(0.2) : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(widget.brother.avatarUrl),
                backgroundColor: AppColors.surfaceRaised,
              ),
              if (widget.brother.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Name and info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.brother.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.brother.streak} DAY STREAK',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.accent,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          // Nudge Button
          ScaleTransition(
            scale: _nudgeScale,
            child: GestureDetector(
              onTap: _isNudged ? null : _handleNudge,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isNudged ? AppColors.accent.withOpacity(0.1) : AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 14,
                      color: _isNudged ? AppColors.accent : Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isNudged ? 'NUDGED' : 'NUDGE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _isNudged ? AppColors.accent : Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}