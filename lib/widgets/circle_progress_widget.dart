import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../screens/tasks/tasks_screen.dart';
import '../theme/app_theme.dart';

class CircleProgressWidget extends StatefulWidget {
  const CircleProgressWidget({super.key});

  @override
  State<CircleProgressWidget> createState() => _CircleProgressWidgetState();
}

class _CircleProgressWidgetState extends State<CircleProgressWidget> {
  final _supabase = SupabaseService.client;
  List<_CircleProgress> _circles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCircleProgress();
  }

  Future<void> _loadCircleProgress() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final memberRows = await _supabase
          .from('tribe_members')
          .select('tribe_id, tribes(id, name, intensity)')
          .eq('user_id', userId);

      if (memberRows.isEmpty) {
        if (mounted) {
          setState(() {
            _circles = [];
            _loading = false;
          });
        }
        return;
      }

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final List<_CircleProgress> results = [];

      for (final row in memberRows) {
        final circle = row['tribes'] as Map<String, dynamic>;
        final circleId = circle['id'] as String;
        final circleName = circle['name'] as String;
        final intensity = circle['intensity'] as String? ?? 'standard';

        final taskRows = await _supabase
            .from('tasks')
            .select('id, task_type')
            .eq('tribe_id', circleId);

        final circleTasks = taskRows
            .where((t) => !_isSoloMetricTask(t['task_type'] as String? ?? ''))
            .toList();

        final totalTasks = circleTasks.length;
        if (totalTasks == 0) continue;

        final taskIds = circleTasks.map((t) => t['id'] as String).toList();

        final completionRows = await _supabase
            .from('task_completions')
            .select('id')
            .eq('user_id', userId)
            .eq('tribe_id', circleId)
            .inFilter('task_id', taskIds)
            .gte('completed_at', '${todayStr}T00:00:00')
            .lte('completed_at', '${todayStr}T23:59:59');

        final completed = completionRows.length;

        final tribeCompletionRows = await _supabase
            .from('task_completions')
            .select('user_id')
            .eq('tribe_id', circleId)
            .inFilter('task_id', taskIds)
            .gte('completed_at', '${todayStr}T00:00:00')
            .lte('completed_at', '${todayStr}T23:59:59');

        final activeMembers =
            tribeCompletionRows.map((r) => r['user_id']).toSet().length;

        final memberCountRows = await _supabase
            .from('tribe_members')
            .select('id')
            .eq('tribe_id', circleId);

        results.add(_CircleProgress(
          circleId: circleId,
          name: circleName,
          intensity: intensity,
          completed: completed,
          total: totalTasks,
          activeMembersToday: activeMembers,
          totalMembers: memberCountRows.length,
        ));
      }

      if (mounted) {
        setState(() {
          _circles = results;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('CircleProgressWidget error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isSoloMetricTask(String taskType) {
    return ['water', 'steps', 'reading'].contains(taskType.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
        ),
      );
    }

    if (_circles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
          child: Text('CIRCLE PROGRESS', style: AppTextStyles.label),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _circles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) => _CircleCard(progress: _circles[i]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CircleCard extends StatelessWidget {
  final _CircleProgress progress;
  const _CircleCard({required this.progress});

  Color get _intensityColor {
    switch (progress.intensity) {
      case 'hardcore':
        return AppColors.danger;
      case 'casual':
        return AppColors.success;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = progress.total > 0 ? progress.completed / progress.total : 0.0;
    final pct = (ratio * 100).round();
    final accent = _intensityColor;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TasksScreen(
              circleId: progress.circleId,
              circleName: progress.name,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progress.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: ratio,
                      strokeWidth: 6,
                      backgroundColor: AppColors.surfaceRaised,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${progress.completed}/${progress.total} TASKS',
              style: AppTextStyles.label.copyWith(fontSize: 9),
            ),
            const SizedBox(height: 4),
            Text(
              '${progress.activeMembersToday} ACTIVE TODAY',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 9, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleProgress {
  final String circleId;
  final String name;
  final String intensity;
  final int completed;
  final int total;
  final int activeMembersToday;
  final int totalMembers;

  const _CircleProgress({
    required this.circleId,
    required this.name,
    required this.intensity,
    required this.completed,
    required this.total,
    required this.activeMembersToday,
    required this.totalMembers,
  });
}