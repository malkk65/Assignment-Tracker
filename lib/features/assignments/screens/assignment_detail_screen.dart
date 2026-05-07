import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/cache/user_cache.dart';
import '../../../core/services/assignment_service.dart';
import '../models/assignment.dart';

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

  Future<void> _downloadPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading answer: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

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
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
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
              _buildResources(),
            ],
            const SizedBox(height: 30),
            UserCache.isAdmin ? _buildAdminSubmissions() : _buildStudentUploadSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildChip(widget.assignment.courseCode, AppColors.primary.withValues(alpha: 0.1), AppColors.primary),
            const SizedBox(width: 10),
            _buildChip(
              '${widget.assignment.priority.toUpperCase()} PRIORITY',
              _priorityColor.withValues(alpha: 0.1),
              _priorityColor,
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

  Widget _buildResources() {
    return GestureDetector(
      onTap: () => _downloadPdf(widget.assignment.fileAttachmentUrl!),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.description, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.assignment.fileAttachmentName ?? 'Attached PDF File',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.download_for_offline_outlined, color: AppColors.primary),
          ],
        ),
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream: AssignmentService.getSubmissionsStream(widget.assignment.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error loading submissions', style: TextStyle(color: AppColors.error));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text('No submissions yet.', style: TextStyle(color: AppColors.textSecondary));
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return ListTile(
                  tileColor: AppColors.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(data['studentName'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['fileName'] ?? 'submission.pdf', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.download, color: AppColors.primary),
                    onPressed: () => _downloadPdf(data['fileUrl']),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildChip(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Color get _priorityColor {
    switch (widget.assignment.priority) {
      case 'high':
        return AppColors.highPriority;
      case 'medium':
        return AppColors.mediumPriority;
      default:
        return AppColors.lowPriority;
    }
  }
}
