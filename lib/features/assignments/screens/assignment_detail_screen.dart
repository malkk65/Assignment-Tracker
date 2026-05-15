import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/cache/user_cache.dart';
import '../../../core/services/assignment_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/assignment.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../admin/screens/admin_add_assignment_screen.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final Assignment assignment;

  const AssignmentDetailScreen({
    super.key,
    required this.assignment,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  bool _isUploading = false;

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file')),
        );
      }
    }
  }

  Future<void> _submitAnswer() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      try {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileUrl = await AssignmentService.uploadFile(file, 'student_submissions');

        final user = FirebaseAuth.instance.currentUser!;
        await AssignmentService.submitStudentAnswer(
          assignmentId: widget.assignment.id,
          studentId: user.uid,
          studentName: user.displayName ?? 'Student',
          fileUrl: fileUrl,
          fileName: fileName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Answer submitted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          // Strip the "Exception: " prefix for a cleaner user message.
          final message = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // ── Admin Actions ──

  void _editAssignment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAddAssignmentScreen(
          existingAssignment: widget.assignment,
        ),
      ),
    );
    // If edit was saved, go back so the list refreshes
    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _deleteAssignment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: 'Delete Assignment',
        message: 'Are you sure you want to delete this assignment? This action cannot be undone.',
        icon: Icons.delete_outline,
        iconColor: AppColors.error,
        primaryButtonText: 'Delete',
        onPrimaryPressed: () {},
      ),
    );

    if (confirm == true) {
      try {
        await AssignmentService.deleteAssignment(widget.assignment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment deleted.')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')),
          );
        }
      }
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Assignment Detail'),
        actions: [
          // Admin gets edit & delete actions
          if (UserCache.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              tooltip: 'Edit Assignment',
              onPressed: _editAssignment,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Delete Assignment',
              onPressed: _deleteAssignment,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildProgressSection(),
            if (widget.assignment.fileAttachmentUrl != null) ...[
              const SizedBox(height: 24),
              _buildFileAttachment(),
            ],
            const SizedBox(height: 30),
            UserCache.isAdmin
                ? _buildAdminSubmissions()
                : _buildStudentStatusSection(),
          ],
        ),
      ),
    );
  }

  /// شاشة تظهر حالة تسليم الطالب (هل سلم أم لا)
  Widget _buildStudentStatusSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.assignment.id)
          .collection('submissions')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 50, color: AppColors.success),
                const SizedBox(height: 10),
                const Text(
                  'Assignment Submitted!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.success),
                ),
                const SizedBox(height: 5),
                Text(
                  'File: ${data['fileName']}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openPdf(data['fileUrl']),
                      icon: const Icon(Icons.remove_red_eye_outlined),
                      label: const Text('View'),
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      onPressed: () => _unsubmitAnswer(data['fileUrl']),
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      label: const Text('Unsubmit', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return _buildStudentUploadSection();
      },
    );
  }

  Future<void> _unsubmitAnswer(String fileUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: 'Unsubmit Assignment?',
        message: 'This will remove your submission. You can upload a new file after unsubmitting.',
        icon: Icons.assignment_return_outlined,
        iconColor: AppColors.error,
        primaryButtonText: 'Unsubmit',
        onPrimaryPressed: () {},
      ),
    );

    if (confirm == true) {
      setState(() => _isUploading = true);
      try {
        await AssignmentService.deleteSubmission(
          widget.assignment.id,
          FirebaseAuth.instance.currentUser!.uid,
        );
        await StorageService.deleteFile(fileUrl);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission removed.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge(
              label: widget.assignment.courseCode,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              textColor: AppColors.primary,
            ),
            const SizedBox(width: 10),
            StatusBadge(
              label: '${widget.assignment.priority.toUpperCase()} PRIORITY',
              backgroundColor: widget.assignment.priorityColor.withValues(alpha: 0.1),
              textColor: widget.assignment.priorityColor,
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          widget.assignment.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        if (widget.assignment.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.assignment.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${widget.assignment.progress}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.assignment.progress / 100,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(
                widget.assignment.isCompleted ? AppColors.success : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: widget.assignment.isOverdue ? AppColors.urgent : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.assignment.dueDateLabel,
                style: TextStyle(
                  color: widget.assignment.isOverdue ? AppColors.urgent : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Prominent file attachment card with download button.
  Widget _buildFileAttachment() {
    final fileName = widget.assignment.fileAttachmentName ?? 'Assignment File.pdf';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_file, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Assignment File',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // File card
          InkWell(
            onTap: () => _openPdf(widget.assignment.fileAttachmentUrl!),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap to view or download',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentUploadSection() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 50, color: AppColors.primary),
          const SizedBox(height: 10),
          const Text(
            'Upload Your Answer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'PDF format only',
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submitAnswer,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Submit PDF '),
                        Icon(Icons.send, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSubmissions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Student Submissions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream: AssignmentService.getSubmissionsStream(widget.assignment.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text(
                'Error loading submissions',
                style: TextStyle(color: AppColors.error),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 40, color: AppColors.textHint),
                      SizedBox(height: 8),
                      Text(
                        'No submissions yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return ListTile(
                  tileColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    data['studentName'] ?? 'Unknown Student',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data['fileName'] ?? 'submission.pdf',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download, color: AppColors.primary),
                    onPressed: () => _openPdf(data['fileUrl']),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
