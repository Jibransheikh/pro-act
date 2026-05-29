import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';

class CircleTab extends StatefulWidget {
  const CircleTab({super.key});

  @override
  State<CircleTab> createState() => _CircleTabState();
}

class _CircleTabState extends State<CircleTab> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      final memberships = await _supabase
          .from('tribe_members')
          .select('tribe_id')
          .eq('user_id', userId);

      final tribeIds = memberships
          .map((m) => m['tribe_id'] as String)
          .toList();

      if (tribeIds.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final events = await _supabase
          .from('feed_events')
          .select('*, profiles(full_name)')
          .inFilter('tribe_id', tribeIds)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(events);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading feed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

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
                  Text('FEED', style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  const Text('What\'s happening.', style: AppTextStyles.titleLarge),
                ],
              ),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            )
          else if (_events.isEmpty)
            SliverToBoxAdapter(child: _emptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = _events[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: _FeedEventCard(event: event),
                  );
                },
                childCount: _events.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Column(
          children: [
            Icon(Icons.bolt_outlined, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 16),
            Text('NOTHING HERE YET', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Activity from your circles will show up live here once completions start.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const _FeedEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final name = event['profiles']?['full_name'] ?? 'Someone';
    final type = event['event_type'] as String;
    final createdAt = DateTime.parse(event['created_at']);
    final timeAgo = _timeAgo(createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _eventColor(type).withOpacity(0.1),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _eventColor(type)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: name.toUpperCase(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      TextSpan(
                        text: ' ${_eventText(type)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(timeAgo.toUpperCase(), style: AppTextStyles.label.copyWith(fontSize: 9)),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _eventColor(type),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'task_complete': return AppColors.success;
      case 'task_missed': return AppColors.danger;
      case 'joined_tribe': return AppColors.accent;
      default: return AppColors.textSecondary;
    }
  }

  String _eventText(String type) {
    switch (type) {
      case 'task_complete': return 'completed a task ✓';
      case 'task_missed': return 'missed a task ✗';
      case 'joined_tribe': return 'joined the circle';
      default: return 'performed an action';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}