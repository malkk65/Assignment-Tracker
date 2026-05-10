import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../../../core/theme/app_colors.dart';
import '../../../core/models/assignment.dart';
import '../../../core/services/assignment_service.dart';

/// Screen for both creating and editing assignments.
///
/// Pass an [existingAssignment] to enable edit mode.
class AdminAddAssignmentScreen extends StatefulWidget {
  final Assignment? existingAssignment;

  const AdminAddAssignmentScreen({super.key, this.existingAssignment});

  bool get isEditing => existingAssignment != null;

  @override
  State<AdminAddAssignmentScreen> createState() => _AdminAddAssignmentScreenState();
}

class _AdminAddAssignmentScreenState extends State<AdminAddAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _courseCodeController;
  late final TextEditingController _courseNameController;

  late DateTime _selectedDate;
  late String _priority;
  bool _isLoading = false;
  File? _selectedFile;

  // Track the existing file attachment (for edit mode)
  String? _existingFileUrl;
  String? _existingFileName;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAssignment;
    _titleController = TextEditingController(text: a?.title ?? '');
    _descController = TextEditingController(text: a?.description ?? '');
    _courseCodeController = TextEditingController(text: a?.courseCode ?? '');
    _courseNameController = TextEditingController(text: a?.courseName ?? '');
    _selectedDate = a?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _priority = a?.priority ?? 'medium';
    _existingFileUrl = a?.fileAttachmentUrl;
    _existingFileName = a?.fileAttachmentName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _courseCodeController.dispose();
    _courseNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        // Clear existing file when new one is picked
        _existingFileUrl = null;
        _existingFileName = null;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _existingFileUrl = null;
      _existingFileName = null;
    });
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? fileUrl = _existingFileUrl;
      String? fileName = _existingFileName;

      // Upload new file if one was picked
      if (_selectedFile != null) {
        fileName = path.basename(_selectedFile!.path);
        fileUrl = await AssignmentService.uploadFile(_selectedFile!, 'assignment_files');
      }

      final assignment = Assignment(
        id: widget.existingAssignment?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        courseCode: _courseCodeController.text.trim(),
        courseName: _courseNameController.text.trim(),
        dueDate: _selectedDate,
        status: widget.existingAssignment?.status ?? 'pending',
        priority: _priority,
        progress: widget.existingAssignment?.progress ?? 0,
        fileAttachmentUrl: fileUrl,
        fileAttachmentName: fileName,
      );

      if (widget.isEditing) {
        await AssignmentService.updateAssignment(assignment);
      } else {
        await AssignmentService.createAssignment(assignment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Assignment updated successfully!'
                : 'Assignment added successfully!'),
          ),
        );
        Navigator.pop(context, true); // Return true to signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──

  String get _displayFileName {
    if (_selectedFile != null) return path.basename(_selectedFile!.path);
    if (_existingFileName != null) return _existingFileName!;
    return 'No PDF selected';
  }

  bool get _hasFile => _selectedFile != null || _existingFileUrl != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Assignment' : 'Add Assignment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEditing ? 'Update Assignment' : 'Create New Assignment',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: const Icon(Icons.title, color: AppColors.textHint),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 15),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.description, color: AppColors.textHint),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),

              // Course Code & Name
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _courseCodeController,
                      decoration: InputDecoration(
                        labelText: 'Course Code',
                        prefixIcon: const Icon(Icons.code, color: AppColors.textHint),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _courseNameController,
                      decoration: InputDecoration(
                        labelText: 'Course Name',
                        prefixIcon: const Icon(Icons.book, color: AppColors.textHint),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Due Date & Priority
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.textHint, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _priority = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // File Picker
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _hasFile ? Icons.picture_as_pdf : Icons.upload_file,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasFile ? 'PDF Attached' : 'Attachment (Optional)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _displayFileName,
                            style: TextStyle(
                              color: _hasFile ? AppColors.success : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (_hasFile)
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                        onPressed: _removeFile,
                        tooltip: 'Remove file',
                      ),
                    TextButton(
                      onPressed: _pickFile,
                      child: Text(_hasFile ? 'Replace' : 'Select'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAssignment,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.isEditing ? 'Update Assignment' : 'Add Assignment',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
