import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../evaluations/services/evaluator_catalog_service.dart';
import '../widgets/ideathon_assignee_select_row.dart';
import '../../idea/models/idea_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_service.dart';

/// Department-admin ideathon creation form (shortlisted ideas only).
class CreateIdeathonWorkspace extends StatefulWidget {
  const CreateIdeathonWorkspace({super.key, required this.user, required this.onCreated});

  final UserModel user;
  final ValueChanged<String> onCreated;

  @override
  State<CreateIdeathonWorkspace> createState() => _CreateIdeathonWorkspaceState();
}

class _CreateIdeathonWorkspaceState extends State<CreateIdeathonWorkspace> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _eventDate = DateTime.now().add(const Duration(days: 14));

  bool _loading = true;
  bool _saving = false;
  List<IdeaModel> _shortlisted = <IdeaModel>[];
  List<UserModel> _evaluators = <UserModel>[];
  List<UserModel> _coordinators = <UserModel>[];
  final Set<String> _selectedIdeaIds = <String>{};
  final Set<String> _selectedJudgeIds = <String>{};
  final Set<String> _selectedCoordinatorIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final String orgId = widget.user.orgId.trim();
    final String dept = widget.user.departmentCode.trim();
    final List<IdeaModel> ideas =
        await IdeathonService.fetchShortlistedIdeas(orgId: orgId, departmentCode: dept);
    final List<UserModel> evaluators = await EvaluatorCatalogService.loadEvaluators(orgId: orgId);
    final List<UserModel> coordinators = await _loadCoordinators(orgId: orgId, dept: dept);
    if (!mounted) return;
    setState(() {
      _shortlisted = ideas;
      _evaluators = evaluators;
      _coordinators = coordinators;
      _loading = false;
    });
  }

  Future<List<UserModel>> _loadCoordinators({required String orgId, required String dept}) async {
    final String normalizedDept = dept.trim().toUpperCase();
    final List<Future<QuerySnapshot<Map<String, dynamic>>>> queries = <Future<QuerySnapshot<Map<String, dynamic>>>>[
      FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: orgId)
          .where('role', isEqualTo: UserRole.faculty.code)
          .get(),
      FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: orgId)
          .where('role', isEqualTo: UserRole.departmentAdmin.code)
          .get(),
    ];
    final List<QuerySnapshot<Map<String, dynamic>>> results =
        await Future.wait<QuerySnapshot<Map<String, dynamic>>>(queries);
    final Map<String, UserModel> byId = <String, UserModel>{};
    for (final QuerySnapshot<Map<String, dynamic>> snap in results) {
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        UserModel user = UserModel.fromMap(doc.data());
        if (user.userId.trim().isEmpty) user = user.copyWith(userId: doc.id);
        if (normalizedDept.isNotEmpty && user.departmentCode.trim().toUpperCase() != normalizedDept) {
          continue;
        }
        byId[user.userId] = user;
      }
    }
    final List<UserModel> users = byId.values.toList(growable: false)
      ..sort((UserModel a, UserModel b) => a.displayName.compareTo(b.displayName));
    return users;
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _selectedIdeaIds.isNotEmpty &&
      _selectedJudgeIds.isNotEmpty &&
      !_saving;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);
    try {
      final String id = await IdeathonService.createIdeathon(
        actor: widget.user,
        input: CreateIdeathonInput(
          name: _nameController.text,
          description: _descriptionController.text,
          eventDate: _eventDate,
          ideaIds: _selectedIdeaIds.toList(),
          judgeIds: _selectedJudgeIds.toList(),
          coordinatorIds: _selectedCoordinatorIds.toList(),
        ),
      );
      if (!mounted) return;
      widget.onCreated(id);
      FeedbackService.showSuccess(context, title: 'Ideathon created', message: 'Event scheduled successfully.');
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to create ideathon', message: '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final EdgeInsets pad = EdgeInsets.fromLTRB(
      ResponsiveHelper.isMobile(context) ? 16 : 22,
      8,
      ResponsiveHelper.isMobile(context) ? 16 : 22,
      16,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: pad,
            children: <Widget>[
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Event name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Event date',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(AppIcons.clock, size: 15, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              formatShortDate(_eventDate.toLocal()),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Shortlisted ideas', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (_shortlisted.isEmpty)
                const Text('No shortlisted ideas available.', style: TextStyle(color: Color(0xFF64748B)))
              else
                ..._shortlisted.map(
                  (IdeaModel idea) => CheckboxListTile(
                    value: _selectedIdeaIds.contains(idea.ideaId),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedIdeaIds.add(idea.ideaId);
                        } else {
                          _selectedIdeaIds.remove(idea.ideaId);
                        }
                      });
                    },
                    title: Text(idea.ideaTitle.trim().isEmpty ? idea.ideaId : idea.ideaTitle.trim()),
                    subtitle: Text(idea.problemTitle.trim().isEmpty ? '—' : idea.problemTitle.trim()),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
              const SizedBox(height: 16),
              _buildJudgesCoordinatorsSection(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildJudgesCoordinatorsSection(BuildContext context) {
    final bool sideBySide = !ResponsiveHelper.isMobile(context);
    final Widget judges = _buildAssigneeList(
      title: 'Judges',
      users: _evaluators,
      selectedIds: _selectedJudgeIds,
      showJudgeType: true,
      onToggle: (String userId) => setState(() {
        if (_selectedJudgeIds.contains(userId)) {
          _selectedJudgeIds.remove(userId);
        } else {
          _selectedJudgeIds.add(userId);
        }
      }),
      emptyMessage: 'No judges available.',
    );
    final Widget coordinators = _buildAssigneeList(
      title: 'Coordinators',
      users: _coordinators,
      selectedIds: _selectedCoordinatorIds,
      leadingIcon: AppIcons.coordinator,
      onToggle: (String userId) => setState(() {
        if (_selectedCoordinatorIds.contains(userId)) {
          _selectedCoordinatorIds.remove(userId);
        } else {
          _selectedCoordinatorIds.add(userId);
        }
      }),
      emptyMessage: 'No coordinators available.',
    );

    if (sideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: judges),
          const SizedBox(width: 12),
          Expanded(child: coordinators),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        judges,
        const SizedBox(height: 14),
        coordinators,
      ],
    );
  }

  Widget _buildAssigneeList({
    required String title,
    required List<UserModel> users,
    required Set<String> selectedIds,
    required ValueChanged<String> onToggle,
    required String emptyMessage,
    IconData? leadingIcon,
    bool showJudgeType = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (users.isEmpty)
          Text(emptyMessage, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))
        else
          ...users.map(
            (UserModel user) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IdeathonAssigneeSelectRow(
                user: user,
                selected: selectedIds.contains(user.userId),
                leadingIcon: leadingIcon,
                showJudgeType: showJudgeType,
                onToggle: () => onToggle(user.userId),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.isMobile(context) ? 16 : 22,
        12,
        ResponsiveHelper.isMobile(context) ? 16 : 22,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      child: FilledButton.icon(
        onPressed: _canSubmit ? _submit : null,
        icon: _saving
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(AppIcons.add, size: 18),
        label: const Text('Create Ideathon'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          backgroundColor: const Color(0xFF6A38FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
