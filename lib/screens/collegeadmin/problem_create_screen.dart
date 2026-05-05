import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../constants/problem_constants.dart';
import '../../models/enums/user_role.dart';
import '../../models/problem_model.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/problem_utils.dart';

class ProblemCreateScreen extends StatefulWidget {
  const ProblemCreateScreen({
    super.key,
    required this.currentUser,
    this.initialProblem,
    this.embedded = false,
    this.onBack,
    this.onSaved,
  });

  final UserModel currentUser;
  final ProblemModel? initialProblem;
  final bool embedded;
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  @override
  State<ProblemCreateScreen> createState() => _ProblemCreateScreenState();
}

class _ProblemCreateScreenState extends State<ProblemCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _themeController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = <String>[];
  final List<PlatformFile> _attachments = <PlatformFile>[];
  String _selectedDepartment = '';
  String _selectedCategory = '';
  List<Map<String, String>> _departmentOptions = <Map<String, String>>[];
  bool _isActive = true;
  bool _isLoadingDepartments = true;
  bool _isSubmitting = false;
  bool _showValidationErrors = false;

  bool get _isEdit => widget.initialProblem != null;
  bool get _isDeptAdmin => UserRole.fromCode(widget.currentUser.role) == UserRole.departmentAdmin;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final initial = widget.initialProblem!;
      _titleController.text = initial.title;
      _descriptionController.text = initial.description;
      _themeController.text = initial.theme;
      _selectedCategory = initial.category;
      _tags.addAll(initial.tags);
      _selectedDepartment = initial.departmentCode;
      _isActive = initial.isActive;
    }
    _loadDepartments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _themeController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final rows = await FirestoreUtils.getDepartmentsByCollege(widget.currentUser.orgId);
      final options = rows
          .map((row) {
            final code = ((row['code'] as String?) ?? '').trim();
            final name = ((row['name'] as String?) ?? '').trim();
            if (code.isEmpty || name.isEmpty) return null;
            return <String, String>{'code': code, 'name': name};
          })
          .whereType<Map<String, String>>()
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _departmentOptions = options;
        if (_isDeptAdmin) {
          _selectedDepartment = widget.currentUser.departmentCode.trim().toUpperCase();
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingDepartments = false);
    }
  }

  void _addTag() {
    final raw = _tagController.text.trim();
    if (raw.isEmpty) return;
    if (!_tags.contains(raw)) {
      setState(() => _tags.add(raw));
    }
    _tagController.clear();
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      for (final file in result.files) {
        final alreadyAdded = _attachments.any((f) => f.name == file.name && f.size == file.size);
        if (!alreadyAdded) {
          _attachments.add(file);
        }
      }
    });
  }

  bool get _isValidForSubmit {
    return _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _selectedDepartment.trim().isNotEmpty &&
        _selectedCategory.trim().isNotEmpty &&
        _themeController.text.trim().isNotEmpty &&
        !_isLoadingDepartments &&
        !_isSubmitting;
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4A67FF), width: 1.4),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_showValidationErrors) {
      setState(() => _showValidationErrors = true);
    }
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedDepartment.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final problemNumber = await ProblemUtils.generateProblemNumber();
      final uploadedAttachments = await ProblemUtils.uploadAttachments(
        files: _attachments,
        problemNumber: problemNumber,
      );
      final attachments = _isEdit
          ? <String>{...widget.initialProblem!.attachments, ...uploadedAttachments}.toList(growable: false)
          : uploadedAttachments;
      final orgTypeName = widget.currentUser.orgType?.name ?? 'college';
      final problem = ProblemModel(
        problemId: widget.initialProblem?.problemId ?? '',
        problemNumber: problemNumber,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        orgId: widget.currentUser.orgId,
        orgType: orgTypeName,
        departmentCode: _selectedDepartment,
        createdBy: widget.currentUser.userId,
        category: _selectedCategory,
        theme: _themeController.text.trim(),
        tags: _tags,
        attachments: attachments,
        isActive: _isActive,
        createdAt: widget.initialProblem?.createdAt ?? DateTime.now(),
        updatedAt: _isEdit ? DateTime.now() : null,
      );
      if (_isEdit) {
        await FirestoreUtils.updateProblem(
          problem.problemId,
          <String, dynamic>{
            'title': problem.title,
            'description': problem.description,
            'departmentCode': problem.departmentCode,
            'category': problem.category,
            'theme': problem.theme,
            'tags': problem.tags,
            'isActive': problem.isActive,
            'attachments': problem.attachments,
          },
        );
      } else {
        await FirestoreUtils.createProblem(problem);
      }
      if (!mounted) return;
      if (widget.embedded) {
        widget.onSaved?.call();
      } else {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop(true);
        } else {
          Navigator.of(context, rootNavigator: true).pop(true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to create problem: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Form(
        key: _formKey,
        autovalidateMode: _showValidationErrors
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        onChanged: () => setState(() {}),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildCard(
                title: 'Basic Info',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _titleController,
                      decoration: _fieldDecoration('Title *', hint: 'Enter problem title'),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return 'Title is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingDepartments)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    else if (_isDeptAdmin)
                      TextFormField(
                        readOnly: true,
                        initialValue: _departmentOptions
                            .where((d) => d['code'] == _selectedDepartment)
                            .map((d) => '${d['name']} (${d['code']})')
                            .cast<String?>()
                            .firstWhere((v) => v != null, orElse: () => _selectedDepartment),
                        decoration: _fieldDecoration('Department *'),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
                        decoration: _fieldDecoration('Department *'),
                        items: _departmentOptions
                            .map(
                              (d) => DropdownMenuItem<String>(
                                value: d['code']!,
                                child: Text('${d['name']} (${d['code']})'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) => setState(() => _selectedDepartment = value ?? ''),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) return 'Department is required';
                          return null;
                        },
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory.isEmpty ? null : _selectedCategory,
                            decoration: _fieldDecoration('Category *'),
                            items: ProblemConstants.categories
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) => setState(() => _selectedCategory = value ?? ''),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) return 'Category is required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _themeController,
                            decoration: _fieldDecoration('Theme *', hint: 'e.g. AI for Social Good'),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) return 'Theme is required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: _fieldDecoration('Tags', hint: 'Add tag and press Enter'),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _addTag,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(60, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map(
                              (tag) => Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(tag),
                                onDeleted: () => setState(() => _tags.remove(tag)),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: _fieldDecoration('Description *', hint: 'Describe the problem clearly'),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return 'Description is required';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildCard(
                title: 'Classification',
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Problem'),
                  subtitle: const Text('Disable only when this problem should be hidden'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ),
              const SizedBox(height: 12),
              _buildCard(
                title: 'Attachments',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _pickAttachments,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Upload files'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: _attachments.isEmpty
                          ? Text(
                              'No files uploaded yet.',
                              style: TextStyle(color: Colors.grey.shade600),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _attachments
                                  .map(
                                    (file) => Chip(
                                      avatar: const Icon(Icons.insert_drive_file_outlined, size: 16),
                                      label: Text(
                                        file.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      deleteIcon: const Icon(Icons.close, size: 18),
                                      onDeleted: () => setState(() => _attachments.remove(file)),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    final bottomBar = SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (widget.embedded) {
                          widget.onBack?.call();
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(128, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _isValidForSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(164, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_isSubmitting ? (_isEdit ? 'Saving...' : 'Creating...') : (_isEdit ? 'Save Problem' : 'Create Problem')),
              ),
            ],
          ),
        ),
      );
    if (widget.embedded) {
      return Container(
        color: const Color(0xFFF5F7FB),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Problems'),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
            bottomBar,
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Problem' : 'Create Problem')),
      backgroundColor: const Color(0xFFF5F7FB),
      body: body,
      bottomNavigationBar: bottomBar,
    );
  }
}
