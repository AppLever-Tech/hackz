import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_columns.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../core/ui/menus/hackz_popup_menu.dart';
import '../../../features/dashboard/chrome/dashboard_chrome_controller.dart';
import '../../../features/dashboard/chrome/dashboard_chrome_scope.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../features/dashboard/chrome/dashboard_session_scope.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../utils/common_helpers.dart';
import '../../attachment/models/attachment_model.dart';
import '../../attachment/services/attachment_service.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import 'package:hackz/core/workspace/workspace_controller.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import '../models/feedback_model.dart';
import '../models/feedback_status.dart';
import '../services/hackz_feedback_service.dart';
import '../widgets/feedback_status_pill.dart';
import '../widgets/feedback_type_pill.dart';

void showFeedbackDetailsPane(
  BuildContext context, {
  required FeedbackModel initial,
  required UserModel viewer,
  required VoidCallback onChanged,
  VoidCallback? onBack,
  String backTooltip = 'Back to Feedback',
}) {
  WorkspaceController.instance.close();
  final DashboardChromeController chrome = DashboardChromeScope.of(context);
  chrome.showOverlay(
    FeedbackDetailsPane(
      key: ValueKey<String>(initial.feedbackId),
      initial: initial,
      viewer: viewer,
      onBack: onBack ?? chrome.clearOverlay,
      onChanged: onChanged,
      backTooltip: backTooltip,
    ),
  );
}

class FeedbackDetailsPane extends StatefulWidget {
  const FeedbackDetailsPane({
    super.key,
    required this.initial,
    required this.viewer,
    required this.onBack,
    required this.onChanged,
    this.backTooltip = 'Back',
  });

  final FeedbackModel initial;
  final UserModel viewer;
  final VoidCallback onBack;
  final VoidCallback onChanged;
  final String backTooltip;

  @override
  State<FeedbackDetailsPane> createState() => _FeedbackDetailsPaneState();
}

class _FeedbackDetailsPaneState extends State<FeedbackDetailsPane> {
  late FeedbackModel _item;
  late FeedbackStatus _status;
  late final TextEditingController _notes;
  bool _saving = false;
  bool _loadingAttachments = true;
  List<AttachmentModel> _attachments = const <AttachmentModel>[];

  bool get _isAdmin => UserRole.fromCode(widget.viewer.role) == UserRole.sysAdmin;

  @override
  void initState() {
    super.initState();
    _item = widget.initial;
    _status = widget.initial.status;
    _notes = TextEditingController(text: widget.initial.internalNotes);
    _loadAttachmentsAndOrg();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadAttachmentsAndOrg() async {
    List<AttachmentModel> attachments = const <AttachmentModel>[];
    try {
      attachments = await AttachmentService.fetchActiveAttachments(
        entityType: AttachmentEntityType.feedback,
        entityId: _item.feedbackId,
      );
    } catch (_) {}

    FeedbackModel item = _item;
    if (item.organizationName.trim().isEmpty && item.organizationId.trim().isNotEmpty) {
      final String name =
          await HackzFeedbackService.resolveOrganizationName(item.organizationId);
      if (name.isNotEmpty) {
        item = item.copyWith(organizationName: name);
      }
    }

    if (!mounted) return;
    setState(() {
      _item = item;
      _attachments = attachments;
      _loadingAttachments = false;
    });
  }

  Future<void> _saveAdmin() async {
    if (!_isAdmin || _saving) return;
    setState(() => _saving = true);
    try {
      await HackzFeedbackService.updateAdminFields(
        feedbackId: _item.feedbackId,
        status: _status,
        internalNotes: _notes.text,
      );
      final FeedbackModel? refreshed =
          await HackzFeedbackService.fetchById(_item.feedbackId);
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (refreshed != null) {
          _item = refreshed.organizationName.trim().isEmpty &&
                  _item.organizationName.trim().isNotEmpty
              ? refreshed.copyWith(organizationName: _item.organizationName)
              : refreshed;
          _status = _item.status;
        }
      });
      widget.onChanged();
      FeedbackService.showSuccess(
        context,
        title: 'Saved',
        message: 'Feedback status and notes updated.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      FeedbackService.showError(context, title: 'Save failed', message: '$e');
    }
  }

  void _openAttachment(AttachmentModel attachment) {
    final String id = attachment.attachmentId.trim();
    if (id.isEmpty) return;
    WorkspaceNavigator.openAttachment(context, id);
  }

  static IconData _statusIcon(FeedbackStatus status) {
    return switch (status) {
      FeedbackStatus.open => Icons.fiber_new_rounded,
      FeedbackStatus.inReview => Icons.hourglass_top_rounded,
      FeedbackStatus.completed => Icons.check_circle_outline,
      FeedbackStatus.closed => Icons.inventory_2_outlined,
    };
  }

  Widget _metaField(String label, Widget value, {bool shrinkValue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (shrinkValue)
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: value,
            )
          else
            Expanded(child: value),
        ],
      ),
    );
  }

  Widget _plain(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _attachmentsValue() {
    if (_loadingAttachments) {
      return const HkzProgressIndicator(size: 18);
    }
    if (_attachments.isEmpty) {
      return _plain('—');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: _attachments.map((AttachmentModel a) {
        final String name = a.fileName.trim().isEmpty ? 'Attachment' : a.fileName.trim();
        return ContextPill(
          label: name,
          icon: AppIcons.attachments,
          semantic: ContextPillSemantic.generic,
          tooltip: 'Open attachment in workspace',
          onTap: () => _openAttachment(a),
          compact: true,
          fitContent: true,
          maxWidth: 220,
        );
      }).toList(growable: false),
    );
  }

  Widget _statusMenuTrigger() {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HackzPopupMenuStyle.panelBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_statusIcon(_status), size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            _status.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF475569)),
        ],
      ),
    );
  }

  Widget _adminStatusAndSave() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PopupMenuButton<FeedbackStatus>(
          tooltip: 'Change status',
          enabled: !_saving,
          color: HackzPopupMenuStyle.panelColor,
          elevation: 14,
          shadowColor: HackzPopupMenuStyle.panelShadowColor,
          surfaceTintColor: Colors.transparent,
          position: PopupMenuPosition.under,
          offset: HackzPopupMenuStyle.defaultOffset,
          constraints: const BoxConstraints(minWidth: HackzPopupMenuStyle.defaultMinWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HackzPopupMenuStyle.panelRadius),
            side: const BorderSide(color: HackzPopupMenuStyle.panelBorderColor),
          ),
          padding: EdgeInsets.zero,
          onSelected: (FeedbackStatus value) => setState(() => _status = value),
          itemBuilder: (BuildContext context) {
            return FeedbackStatus.lifecycle
                .map(
                  (FeedbackStatus s) => PopupMenuItem<FeedbackStatus>(
                    value: s,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: HackzPopupMenuItemTile(
                      icon: _statusIcon(s),
                      label: s.label,
                      selected: _status == s,
                    ),
                  ),
                )
                .toList(growable: false);
          },
          child: _statusMenuTrigger(),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _saving ? null : _saveAdmin,
          icon: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: HkzProgressIndicator(size: 14),
                )
              : const Icon(Icons.save_outlined, size: 16),
          label: const Text('Save'),
          style: MobileToolbarButtonStyles.filled(compact: true),
        ),
      ],
    );
  }

  Widget _topPillsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        FeedbackTypePill(type: _item.type),
        const SizedBox(width: 8),
        FeedbackStatusPill(status: _isAdmin ? _status : _item.status),
        if (_isAdmin) ...<Widget>[
          const Spacer(),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: _adminStatusAndSave(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _metadataSection() {
    final Widget left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _metaField('Reporter', _plain(_item.submittedByName)),
        _metaField('Role', _plain(_item.role)),
        _metaField('Organization', _plain(_item.organizationDisplayName)),
        _metaField(
          'Department',
          _plain(_item.departmentId.isEmpty ? '—' : _item.departmentId),
        ),
        _metaField(
          'App Version',
          _plain(_item.appVersion.isEmpty ? '—' : _item.appVersion),
        ),
      ],
    );

    final Widget right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _metaField(
          'Platform',
          _plain(_item.platform.isEmpty ? '—' : _item.platform),
        ),
        _metaField(
          'Screen',
          _plain(_item.screenName.isEmpty ? '—' : _item.screenName),
        ),
        _metaField('Created', _plain(formatDateTime(_item.createdAt))),
        _metaField('Updated', _plain(formatDateTime(_item.updatedAt))),
        _metaField('Attachments', _attachmentsValue(), shrinkValue: true),
      ],
    );

    return ResponsiveColumns(
      first: left,
      second: right,
      spacing: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final DashboardSessionScope session = DashboardSessionScope.of(context);
    final ColorScheme cs = Theme.of(context).colorScheme;

    final Widget header = DashboardPageHeader(
      title: _item.title.isEmpty ? 'Feedback' : _item.title,
      titleIcon: AppIcons.feedback,
      user: session.user,
      onLogout: session.onLogout,
      onUserTap: () => WorkspaceNavigator.openUser(context, session.user.userId),
      leading: IconButton(
        onPressed: widget.onBack,
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: widget.backTooltip,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          header,
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _topPillsRow(),
                  const SizedBox(height: 16),
                  Text(
                    _item.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _item.description,
                    style: TextStyle(fontSize: 14.5, height: 1.45, color: cs.onSurface),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _metadataSection(),
                  if (_isAdmin) ...<Widget>[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Internal Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notes,
                      enabled: !_saving,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Visible only to System Admin',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
