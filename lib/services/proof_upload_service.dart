import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../theme/app_theme.dart';

class ProofUploadService {
  static SupabaseClient get _supabase => SupabaseService.client;
  static final _picker = ImagePicker();

  static Future<String> pickAndUpload({
    required String taskId,
    required ImageSource source,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw ProofUploadException('Not logged in.');

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 82,
    );
    if (picked == null) throw ProofUploadException('No image selected.');

    final ts = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/$taskId/$ts.jpg';

    final bytes = await File(picked.path).readAsBytes();
    await _supabase.storage.from('task-proofs').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    final url =
        _supabase.storage.from('task-proofs').getPublicUrl(storagePath);
    return url;
  }
}

class ProofUploadException implements Exception {
  final String message;
  ProofUploadException(this.message);
  @override
  String toString() => 'ProofUploadException: $message';
}

class ProofSubmissionSheet extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final bool requiresProofPhoto;

  const ProofSubmissionSheet({
    super.key,
    required this.taskId,
    required this.taskTitle,
    this.requiresProofPhoto = false,
  });

  static Future<ProofResult?> show(
    BuildContext context, {
    required String taskId,
    required String taskTitle,
    bool requiresProofPhoto = false,
  }) {
    return showModalBottomSheet<ProofResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProofSubmissionSheet(
        taskId: taskId,
        taskTitle: taskTitle,
        requiresProofPhoto: requiresProofPhoto,
      ),
    );
  }

  @override
  State<ProofSubmissionSheet> createState() => _ProofSubmissionSheetState();
}

class _ProofSubmissionSheetState extends State<ProofSubmissionSheet> {
  final _textController = TextEditingController();
  String? _proofImageUrl;
  String? _localImagePath;
  bool _uploading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImageWithPreview(ImageSource source) async {
    setState(() {
      _uploading = true;
      _errorMessage = null;
    });
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 82,
      );
      if (picked == null) {
        setState(() => _uploading = false);
        return;
      }

      setState(() => _localImagePath = picked.path);

      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw ProofUploadException('Not logged in.');
      final ts = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/${widget.taskId}/$ts.jpg';
      final bytes = await File(picked.path).readAsBytes();
      await SupabaseService.client.storage.from('task-proofs').uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
                contentType: 'image/jpeg', upsert: false),
          );
      final url = SupabaseService.client.storage
          .from('task-proofs')
          .getPublicUrl(storagePath);

      setState(() {
        _proofImageUrl = url;
        _uploading = false;
      });
    } on ProofUploadException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _uploading = false;
        _localImagePath = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed. Please try again.';
        _uploading = false;
        _localImagePath = null;
      });
    }
  }

  void _submit() {
    if (widget.requiresProofPhoto && _proofImageUrl == null) {
      setState(() => _errorMessage = 'Photo proof is required for this task.');
      return;
    }
    Navigator.of(context).pop(ProofResult(
      proofText: _textController.text.trim(),
      proofImageUrl: _proofImageUrl,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Submit Proof',
                style: AppTextStyles.displayMedium.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                widget.taskTitle,
                style: AppTextStyles.body,
              ),

              const SizedBox(height: 24),

              _SectionLabel(
                label: 'PHOTO PROOF',
                required: widget.requiresProofPhoto,
              ),
              const SizedBox(height: 10),

              if (_localImagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.file(
                        File(_localImagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _localImagePath = null;
                            _proofImageUrl = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      if (_proofImageUrl != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_done,
                                    color: Colors.black, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Uploaded',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else if (_uploading) ...[
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Uploading…',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _PhotoButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: () =>
                            _pickImageWithPreview(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PhotoButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: () =>
                            _pickImageWithPreview(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              _SectionLabel(label: 'NOTE (optional)'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _textController,
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add a note about this completion…',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                    fillColor: Colors.transparent,
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.danger, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploading ? null : _submit,
                  child: const Text(
                    'MARK COMPLETE',
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _SectionLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.label,
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '•',
            style: TextStyle(color: AppColors.danger, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PhotoButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accent, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.label,
            ),
          ],
        ),
      ),
    );
  }
}

class ProofResult {
  final String? proofText;
  final String? proofImageUrl;
  const ProofResult({this.proofText, this.proofImageUrl});
}