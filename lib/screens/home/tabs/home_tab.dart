import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/vow.dart';
import '../../../widgets/circle_progress_widget.dart';
import '../../../services/progress_service.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Vow> _vows = List.from(dummyVows);

  void _toggleVow(int index) {
    setState(() {
      final currentStatus = _vows[index].status;
      _vows[index] = _vows[index].copyWith(
        status: currentStatus == VowStatus.completed 
            ? VowStatus.pending 
            : VowStatus.completed,
      );
    });
  }

  int get _completedCount => _vows.where((v) => v.status == VowStatus.completed).length;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateTime.now().weekday == 7 ? 'SUNDAY' : 
                        DateTime.now().weekday == 1 ? 'MONDAY' :
                        DateTime.now().weekday == 2 ? 'TUESDAY' :
                        DateTime.now().weekday == 3 ? 'WEDNESDAY' :
                        DateTime.now().weekday == 4 ? 'THURSDAY' :
                        DateTime.now().weekday == 5 ? 'FRIDAY' : 'SATURDAY',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 2),
                      const Text('The vow holds.', style: AppTextStyles.titleLarge),
                    ],
                  ),
                  _BrandIcon(),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // Profile Quick Access
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=jibraan'),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Jibraan Sheikh',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Circle Progress
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: CircleProgressWidget(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Daily Metrics Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text("DAILY METRICS", style: AppTextStyles.label),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Metrics Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _MetricsSection(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Penalty Wheel Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _PenaltyBanner(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Today's vows section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("TODAY'S VOWS", style: AppTextStyles.label),
                  Text(
                    '$_completedCount / ${_vows.length} held',
                    style: AppTextStyles.label.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Vows list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final vow = _vows[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _VowTile(
                      vow: vow,
                      onToggle: () => _toggleVow(index),
                    ),
                  );
                },
                childCount: _vows.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Wheel of Excuses Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _WheelBanner(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Active challenge section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('ACTIVE CHALLENGE', style: AppTextStyles.label),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _NoChallengeCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _VowTile extends StatelessWidget {
  final Vow vow;
  final VoidCallback onToggle;

  const _VowTile({required this.vow, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isCompleted = vow.status == VowStatus.completed;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.accent.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? AppColors.accent.withOpacity(0.3) : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted ? AppColors.accent : AppColors.textMuted,
                  width: 1.5,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                vow.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'PA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _PenaltyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/penalties'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withOpacity(0.2), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gavel_outlined, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The Debt Collector.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Failed a vow? Spin for your penalty.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _WheelBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/wheel'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.surfaceRaised, AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feeling weak?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Spin the Wheel of Excuses.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _NoChallengeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_outlined, color: AppColors.textMuted, size: 32),
          const SizedBox(height: 16),
          const Text(
            'No active challenge.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '75 days. 30 days. Your rules. Your climb.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Start a challenge'),
            ),
          ),
        ],
      ),
    );
  }
}
class _MetricsSection extends StatefulWidget {
  @override
  State<_MetricsSection> createState() => _MetricsSectionState();
}

class _MetricsSectionState extends State<_MetricsSection> {
  Map<String, dynamic> _progress = {};
  bool _loading = true;
  StreamSubscription<StepCount>? _stepSubscription;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _initPedometer();
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final p = await ProgressService.getTodayProgress();
    if (mounted) {
      setState(() {
        _progress = p;
        _loading = false;
      });
    }
  }

  void _initPedometer() {
    _stepSubscription = Pedometer.stepCountStream.listen((event) {
      ProgressService.updateSteps(event.steps);
      if (mounted) {
        setState(() {
          _progress['steps'] = event.steps;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.accent)));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'WATER',
                value: '${_progress['water_ml'] ?? 0}',
                unit: 'ML',
                target: '${_progress['water_target'] ?? 2500}',
                icon: Icons.water_drop_outlined,
                color: Colors.blueAccent,
                onTap: () async {
                  await ProgressService.logWater(250);
                  _loadProgress();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'STEPS',
                value: '${_progress['steps'] ?? 0}',
                unit: 'STEPS',
                target: '${_progress['steps_target'] ?? 8000}',
                icon: Icons.directions_walk,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'READING',
          value: '${_progress['pages_read'] ?? 0}',
          unit: 'PAGES',
          target: '${_progress['pages_target'] ?? 20}',
          icon: Icons.book_outlined,
          color: AppColors.accent,
          isWide: true,
          onTap: () async {
            await ProgressService.logPages(1);
            _loadProgress();
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String target;
  final IconData icon;
  final Color color;
  final bool isWide;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.target,
    required this.icon,
    required this.color,
    this.isWide = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (double.tryParse(value) ?? 0) / (double.tryParse(target) ?? 1);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(fontSize: 9)),
                Icon(icon, size: 14, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: AppTextStyles.titleLarge.copyWith(fontSize: 24)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceRaised,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text('GOAL: $target', style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
