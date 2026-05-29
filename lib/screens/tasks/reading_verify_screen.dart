import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';

class ReadingVerifyScreen extends StatefulWidget {
  final String bookTitle;
  final int pageFrom;
  final int pageTo;
  final VoidCallback onPass;
  final VoidCallback onFail;

  const ReadingVerifyScreen({
    super.key,
    required this.bookTitle,
    required this.pageFrom,
    required this.pageTo,
    required this.onPass,
    required this.onFail,
  });

  @override
  State<ReadingVerifyScreen> createState() => _ReadingVerifyScreenState();
}

class _ReadingVerifyScreenState extends State<ReadingVerifyScreen> {
  List<Map<String, dynamic>> _questions = [];
  List<int?> _selected = [];
  bool _loading = true;
  bool _submitting = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await AIService.generateReadingMCQ(
        bookTitle: widget.bookTitle,
        pageFrom: widget.pageFrom,
        pageTo: widget.pageTo,
      );
      setState(() {
        _questions = questions;
        _selected = List.filled(questions.length, null);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submit() async {
    if (_selected.any((s) => s == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer all questions first.')),
      );
      return;
    }

    setState(() => _submitting = true);

    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selected[i] == _questions[i]['correct']) correct++;
    }

    final passed = correct >= 2;

    setState(() {
      _submitting = false;
      _result = passed ? 'pass' : 'fail';
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      if (passed) {
        widget.onPass();
      } else {
        widget.onFail();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              const Text('READING CHECK', style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text(
                '${widget.bookTitle} — pages ${widget.pageFrom} to ${widget.pageTo}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Answer 2 out of 3 correctly to pass.',
                style: AppTextStyles.label.copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: 32),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.accent),
                        const SizedBox(height: 16),
                        Text('Generating questions...',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                )
              else if (_result != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _result == 'pass'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _result == 'pass'
                              ? AppColors.success
                              : AppColors.danger,
                          size: 72,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _result == 'pass' ? 'VERIFIED.' : 'NOT CONVINCING.',
                          style: AppTextStyles.displayMedium.copyWith(
                            color: _result == 'pass'
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _result == 'pass'
                              ? 'Task marked complete. Keep reading.'
                              : 'Task incomplete. Penalty may apply.',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(_questions.length, (i) {
                          final q = _questions[i];
                          final options =
                              List<String>.from(q['options'] as List);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        q['question'] as String,
                                        style: AppTextStyles.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...List.generate(options.length, (j) {
                                  final isSelected = _selected[i] == j;
                                  final labels = ['A', 'B', 'C', 'D'];
                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _selected[i] = j),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      margin: const EdgeInsets.only(
                                          bottom: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.accent
                                                .withOpacity(0.1)
                                            : AppColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.accent
                                              : AppColors.border,
                                          width: isSelected ? 1.5 : 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.accent
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.accent
                                                    : AppColors.textMuted,
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Center(
                                              child: Text(
                                                labels[j],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: isSelected
                                                      ? Colors.black
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              options[j],
                                              style: AppTextStyles.body.copyWith(
                                                color: isSelected
                                                    ? AppColors.textPrimary
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('SUBMIT ANSWERS'),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}