import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:pedometer/pedometer.dart';
import 'reading_verify_screen.dart';
import '../../services/supabase_service.dart';
import '../../services/proof_upload_service.dart';
import 'package:flutter/foundation.dart';

class TasksScreen extends StatefulWidget {
  final String circleId;
  final String circleName;

  const TasksScreen({
    super.key,
    required this.circleId,
    required this.circleName,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _tasks = [];
  Set<String> _completedToday = {};
  bool _loading = true;
  late Stream<StepCount> _stepCountStream;
  final Map<String, int> _stepCounts = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _initPedometer();
  }

  void _initPedometer() {
    if (kIsWeb) return;
    try {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen((StepCount event) {
        if (!mounted) return;
        final stepsToday = event.steps;
        setState(() {
          for (final task in _tasks) {
            if (task['task_type'] == 'numeric' &&
                (task['numeric_unit'] as String? ?? '').toLowerCase().contains('step')) {
              _stepCounts[task['id'] as String] = stepsToday;
              final target = (task['numeric_target'] as num? ?? 0).toDouble();
              if (stepsToday >= target && !_completedToday.contains(task['id'])) {
                _completeTask(task['id'] as String);
              }
            }
          }
        });
      }).onError((error) {
        debugPrint('Pedometer error: $error');
      });
    } catch (e) {
      debugPrint('Pedometer init error: $e');
    }
  }

  Future<void> _loadTasks() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      final tasks = await _supabase
          .from('tasks')
          .select()
          .eq('tribe_id', widget.circleId)
          .order('created_at', ascending: true);

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final completions = await _supabase
          .from('task_completions')
          .select('task_id')
          .eq('user_id', userId)
          .eq('tribe_id', widget.circleId)
          .gte('completed_at', startOfDay.toIso8601String());

      final completedIds =
          (completions as List).map((c) => c['task_id'] as String).toSet();

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(tasks);
        _completedToday = {..._completedToday, ...completedIds};
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _addTask({
    required String title,
    required String taskType,
    required String proofType,
    double numericTarget = 0,
    String numericUnit = '',
    int durationTarget = 0,
    String bookTitle = '',
    bool aiVerify = false,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('tasks').insert({
        'tribe_id': widget.circleId,
        'created_by': userId,
        'title': title,
        'task_type': taskType,
        'proof_type': proofType,
        'numeric_target': numericTarget,
        'numeric_unit': numericUnit,
        'duration_target': durationTarget,
        'book_title': bookTitle,
        'ai_verify': aiVerify,
        'frequency': 'daily',
      });

      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _completeTask(String taskId, {String? proofText, String? proofImageUrl}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('task_completions').insert({
        'task_id': taskId,
        'user_id': userId,
        'tribe_id': widget.circleId,
        'completed_at': DateTime.now().toIso8601String(),
        'proof_text': proofText,
        'proof_image_url': proofImageUrl,
      });

      await _supabase.from('feed_events').insert({
        'tribe_id': widget.circleId,
        'user_id': userId,
        'event_type': 'task_complete',
        'metadata': {'task_id': taskId},
      });

      setState(() => _completedToday.add(taskId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task completed. Keep going.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      setState(() {
        _tasks.removeWhere((t) => t['id'] == taskId);
        _completedToday.remove(taskId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        title: const Text('DELETE TASK', style: AppTextStyles.titleLarge),
        content: Text(
          'Delete "${task['title']}"? This cannot be undone.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteTask(task['id'] as String);
            },
            child: const Text('DELETE', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedToday.length;
    final total = _tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.circleName.toUpperCase()),
        actions: [
          IconButton(
            onPressed: () => _showAddTask(context),
            icon: const Icon(Icons.add, color: AppColors.accent),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$completed / $total DONE', style: AppTextStyles.label),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTextStyles.label.copyWith(color: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 32),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.accent))
            else if (_tasks.isEmpty)
              _emptyState()
            else
              Expanded(child: _taskList()),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          const Text('No tasks yet.', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          const Text('Tap + to add your first task.', style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _taskList() {
    return ListView.separated(
      itemCount: _tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final task = _tasks[i];
        final taskId = task['id'] as String;
        final isDone = _completedToday.contains(taskId);
        final taskType = task['task_type'] as String? ?? 'checklist';

        return GestureDetector(
          onTap: isDone ? null : () => _handleTaskTap(task),
          onLongPress: () => _showDeleteDialog(task),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDone ? AppColors.success.withOpacity(0.05) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone ? AppColors.success : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: isDone ? AppColors.success : AppColors.textMuted,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isDone ? const Icon(Icons.check, color: Colors.black, size: 16) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] as String,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (taskType == 'numeric' &&
                          (task['numeric_unit'] as String? ?? '').toLowerCase().contains('step'))
                        Text(
                          '${_stepCounts[task['id']] ?? 0} / ${(task['numeric_target'] ?? 0).toInt()} STEPS',
                          style: AppTextStyles.label.copyWith(color: AppColors.accent, fontSize: 10),
                        )
                      else
                        Text(_taskTypeLabel(taskType), style: AppTextStyles.label.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                if (!isDone) const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String _taskTypeLabel(String type) {
    switch (type) {
      case 'numeric': return 'LOG A NUMBER';
      case 'timed': return 'LOG DURATION';
      case 'reading': return 'READING';
      default: return 'CHECKLIST';
    }
  }

  void _handleTaskTap(Map<String, dynamic> task) {
    final proofType = task['proof_type'] as String? ?? 'honour';

    if (proofType == 'photo') {
      _showPhotoProofSheet(task);
    } else {
      _showProofSheet(task);
    }
  }

  void _showPhotoProofSheet(Map<String, dynamic> task) async {
    final result = await ProofSubmissionSheet.show(
      context,
      taskId: task['id'] as String,
      taskTitle: task['title'] as String,
      requiresProofPhoto: true,
    );
    if (result != null) {
      _completeTask(task['id'] as String, proofText: result.proofText, proofImageUrl: result.proofImageUrl);
    }
  }

  void _showProofSheet(Map<String, dynamic> task) {
    final taskType = task['task_type'] as String? ?? 'checklist';
    final numericController = TextEditingController();
    final pageStartController = TextEditingController();
    final pageEndController = TextEditingController();

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
            const Text('SUBMIT PROOF', style: AppTextStyles.displayMedium),
            const SizedBox(height: 8),
            Text(task['title'].toString().toUpperCase(), style: AppTextStyles.label.copyWith(color: AppColors.accent)),
            const SizedBox(height: 32),
            if (taskType == 'numeric' || taskType == 'timed')
              TextField(
                controller: numericController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: taskType == 'numeric' ? 'AMOUNT (${task['numeric_unit']})' : 'MINUTES',
                ),
              ),
            if (taskType == 'reading') ...[
              Text(task['book_title'] ?? 'Book', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextField(controller: pageStartController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'FROM PAGE'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: pageEndController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'TO PAGE'))),
                ],
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (taskType == 'reading' && (task['ai_verify'] as bool? ?? false)) {
                    final from = int.tryParse(pageStartController.text) ?? 1;
                    final to = int.tryParse(pageEndController.text) ?? 1;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ReadingVerifyScreen(
                      bookTitle: task['book_title'] ?? '',
                      pageFrom: from,
                      pageTo: to,
                      onPass: () => _completeTask(task['id']),
                      onFail: () {},
                    )));
                  } else {
                    _completeTask(task['id']);
                  }
                },
                child: const Text('SUBMIT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final unitController = TextEditingController();
    final bookController = TextEditingController();
    String type = 'checklist';
    bool aiVerify = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(32, 32, 32, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ADD TASK', style: AppTextStyles.displayMedium),
              const SizedBox(height: 32),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'TASK NAME')),
              const SizedBox(height: 24),
              const Text('TYPE', style: AppTextStyles.label),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['checklist', 'numeric', 'timed', 'reading'].map((t) => ChoiceChip(
                  label: Text(t.toUpperCase()),
                  selected: type == t,
                  onSelected: (s) => setModalState(() => type = t),
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(color: type == t ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                )).toList(),
              ),
              const SizedBox(height: 24),
              if (type == 'numeric' || type == 'timed')
                TextField(controller: targetController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: type == 'numeric' ? 'TARGET' : 'MINUTES')),
              if (type == 'numeric') TextField(controller: unitController, decoration: const InputDecoration(labelText: 'UNIT')),
              if (type == 'reading') ...[
                TextField(controller: bookController, decoration: const InputDecoration(labelText: 'BOOK TITLE')),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('AI VERIFY', style: AppTextStyles.titleMedium),
                  value: aiVerify,
                  onChanged: (v) => setModalState(() => aiVerify = v),
                  activeColor: AppColors.accent,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _addTask(
                      title: titleController.text,
                      taskType: type,
                      proofType: type == 'reading' && aiVerify ? 'ai_verify' : 'honour',
                      numericTarget: double.tryParse(targetController.text) ?? 0,
                      numericUnit: unitController.text,
                      durationTarget: int.tryParse(targetController.text) ?? 0,
                      bookTitle: bookController.text,
                      aiVerify: aiVerify,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('ADD TASK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}