import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../tasks/tasks_screen.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _myCircles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  Future<void> _loadCircles() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('tribe_members')
          .select('tribe_id, tribes(*)')
          .eq('user_id', userId);

      if (mounted) {
        setState(() {
          _myCircles = List<Map<String, dynamic>>.from(response);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading circles: $e');
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THE CIRCLE', style: AppTextStyles.label),
                      const SizedBox(height: 2),
                      const Text('Brothers in arms.', style: AppTextStyles.titleLarge),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _showCircleOptions(context),
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            )
          else if (_myCircles.isEmpty)
            SliverToBoxAdapter(child: _emptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final circle = _myCircles[i]['tribes'] as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CircleCard(circle: circle, onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TasksScreen(
                              circleId: circle['id'] as String,
                              circleName: circle['name'] as String,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                  childCount: _myCircles.length,
                ),
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
        child: Column(
          children: [
            const Icon(Icons.group_outlined, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 16),
            const Text('NO CIRCLES YET', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Accountability requires a tribe. Join or create one to start.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showCircleOptions(context),
              child: const Text('GET STARTED'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCircleOptions(BuildContext context) {
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
            const Text('MANAGE CIRCLES', style: AppTextStyles.displayMedium),
            const SizedBox(height: 32),
            _OptionTile(
              icon: Icons.add_moderator_outlined,
              title: 'Create a new circle',
              subtitle: 'Lead your own brotherhood',
              onTap: () {
                Navigator.pop(context);
                _showCreateCircle(context);
              },
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.vpn_key_outlined,
              title: 'Join with invite code',
              subtitle: 'Enter a code from a brother',
              onTap: () {
                Navigator.pop(context);
                _showJoinCircle(context);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showCreateCircle(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String intensity = 'standard';

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
              const Text('CREATE CIRCLE', style: AppTextStyles.displayMedium),
              const SizedBox(height: 24),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'CIRCLE NAME')),
              const SizedBox(height: 16),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'DESCRIPTION (OPTIONAL)')),
              const SizedBox(height: 24),
              const Text('INTENSITY', style: AppTextStyles.label),
              const SizedBox(height: 12),
              Row(
                children: ['casual', 'standard', 'hardcore'].map((level) {
                  final isSelected = intensity == level;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => intensity = level),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          level.toUpperCase(),
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
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    await _createCircle(nameController.text.trim(), descController.text.trim(), intensity);
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text('ESTABLISH CIRCLE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinCircle(BuildContext context) {
    final codeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(32, 32, 32, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('JOIN CIRCLE', style: AppTextStyles.displayMedium),
            const SizedBox(height: 8),
            const Text('Enter the 6-digit invite code.', style: AppTextStyles.body),
            const SizedBox(height: 32),
            TextField(
              controller: codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'INVITE CODE', hintText: 'ABC123'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (codeController.text.trim().isEmpty) return;
                  await _joinCircle(codeController.text.trim().toUpperCase());
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('JOIN BROTHERHOOD'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCircle(String name, String description, String intensity) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      final inviteCode = _generateCode();

      final circle = await _supabase.from('tribes').insert({
        'name': name,
        'description': description,
        'intensity': intensity,
        'invite_code': inviteCode,
        'created_by': userId,
      }).select().single();

      await _supabase.from('tribe_members').insert({
        'tribe_id': circle['id'],
        'user_id': userId,
        'role': 'admin',
      });

      await _loadCircles();
    } catch (e) {
      debugPrint('Error creating circle: $e');
    }
  }

  Future<void> _joinCircle(String code) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      final tribes = await _supabase.from('tribes').select().eq('invite_code', code);
      if (tribes.isEmpty) return;

      final tribe = tribes.first;
      await _supabase.from('tribe_members').insert({
        'tribe_id': tribe['id'],
        'user_id': userId,
        'role': 'member',
      });

      await _loadCircles();
    } catch (e) {
      debugPrint('Error joining circle: $e');
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(List.generate(6, (i) => chars.codeUnitAt((now + i * 7) % chars.length)));
  }
}

class _CircleCard extends StatelessWidget {
  final Map<String, dynamic> circle;
  final VoidCallback onTap;
  const _CircleCard({required this.circle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (circle['name'] as String).toUpperCase(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getIntensityColor(circle['intensity']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (circle['intensity'] as String).toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _getIntensityColor(circle['intensity'])),
                  ),
                ),
              ],
            ),
            if (circle['description'] != null && circle['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(circle['description'], style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Text('CODE: ${circle['invite_code']}', style: AppTextStyles.label.copyWith(color: AppColors.accent)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getIntensityColor(String? intensity) {
    switch (intensity) {
      case 'hardcore': return AppColors.danger;
      case 'casual': return AppColors.success;
      default: return AppColors.accent;
    }
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

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
            Icon(icon, color: AppColors.accent, size: 24),
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