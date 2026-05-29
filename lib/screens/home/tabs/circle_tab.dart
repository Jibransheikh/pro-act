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
    if (userId == null) {
      _loadMockFeed();
      return;
    }

    try {
      final memberships = await _supabase
          .from('tribe_members')
          .select('tribe_id')
          .eq('user_id', userId);

      final tribeIds = memberships
          .map((m) => m['tribe_id'] as String)
          .toList();

      if (tribeIds.isEmpty) {
        _loadMockFeed();
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
      _loadMockFeed();
    }
  }

  void _loadMockFeed() {
    if (!mounted) return;
    setState(() {
      _events = [
        {
          'profiles': {'full_name': 'Marcus Aurelius'},
          'event_type': 'task_complete',
          'created_at': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
        },
        {
          'profiles': {'full_name': 'David Goggins'},
          'event_type': 'task_missed',
          'created_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        },
        {
          'profiles': {'full_name': 'Jibraan Sheikh'},
          'event_type': 'joined_tribe',
          'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SOCIAL', style: AppTextStyles.label),
                      const SizedBox(height: 2),
                      const Text('The high stakes.', style: AppTextStyles.titleLarge),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _showChallengeOptions(context),
                    icon: const Icon(Icons.add_task, color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ),

          // Challenges Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIVE CHALLENGES', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  const _ChallengeProgressCard(
                    title: '75 HARD ROADMAP',
                    progress: 0.18,
                    daysLeft: 61,
                    intensity: 'hardcore',
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text('ACTIVITY FEED', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
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

  void _showChallengeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('START A CHALLENGE', style: AppTextStyles.displayMedium),
            const SizedBox(height: 32),
            _ChallengeOptionTile(
              icon: Icons.bolt,
              title: '75 HARD',
              subtitle: 'The ultimate mental toughness program.',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('75 Hard Challenge Started.')));
              },
            ),
            const SizedBox(height: 16),
            _ChallengeOptionTile(
              icon: Icons.edit_note,
              title: 'Custom Challenge',
              subtitle: 'Design your own 30/90-day discipline.',
              onTap: () {
                Navigator.pop(context);
                _showCreateCustomChallenge(context);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showCreateCustomChallenge(BuildContext context) {
    final nameController = TextEditingController();
    int duration = 30;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(32, 32, 32, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CUSTOM CHALLENGE', style: AppTextStyles.displayMedium),
              const SizedBox(height: 24),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'CHALLENGE NAME', hintText: 'e.g. MONK MODE')),
              const SizedBox(height: 24),
              const Text('DURATION (DAYS)', style: AppTextStyles.label),
              const SizedBox(height: 12),
              Row(
                children: [30, 60, 90].map((d) {
                  final isSelected = duration == d;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => duration = d),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$d DAYS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameController.text} Challenge Created.')));
                  },
                  child: const Text('BEGIN CLIMB'),
                ),
              ),
            ],
          ),
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

class _ChallengeProgressCard extends StatelessWidget {
  final String title;
  final double progress;
  final int daysLeft;
  final String intensity;

  const _ChallengeProgressCard({
    required this.title,
    required this.progress,
    required this.daysLeft,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.label.copyWith(color: AppColors.accent)),
              Text('$daysLeft DAYS LEFT', style: AppTextStyles.label.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('${(progress * 100).toInt()}% COMPLETE', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _ChallengeOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChallengeOptionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}