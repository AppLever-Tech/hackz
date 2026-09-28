import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/common/mobile_accordion_section.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../exports/certificate/certificate_event_signatory_store.dart';
import '../../exports/certificate/certificate_image_processing.dart';
import '../../exports/certificate/certificate_signatory_people_loader.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../user/services/user_role_labels.dart';

/// Editable event-level signatory configuration (2 or 3 slots).
class CertificateEventSignatoryConfigurationSection extends StatelessWidget {
  const CertificateEventSignatoryConfigurationSection({
    super.key,
    required this.signatoryCount,
    required this.slots,
    required this.eligiblePeople,
    required this.allEligiblePeople,
    required this.onSignatoryCountChanged,
    required this.onSlotChanged,
    required this.enabled,
  });

  final int signatoryCount;
  final List<CertificateSignatorySlotDraft> slots;
  final List<UserModel> eligiblePeople;
  final List<UserModel> allEligiblePeople;
  final ValueChanged<int> onSignatoryCountChanged;
  final void Function(int index, CertificateSignatorySlotDraft slot) onSlotChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Certificate signatories',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
              ),
            ),
            _countChip(2),
            const SizedBox(width: 6),
            _countChip(3),
          ],
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < signatoryCount; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 2),
          _SignatorySlotEditor(
            key: ValueKey<String>('signatory-$i-${slots[i].userId}-${slots[i].name}'),
            slotIndex: i,
            slot: slots[i],
            eligiblePeople: _peopleForSlot(i),
            allEligiblePeople: allEligiblePeople,
            enabled: enabled,
            onChanged: (CertificateSignatorySlotDraft next) => onSlotChanged(i, next),
          ),
        ],
      ],
    );
  }

  Widget _countChip(int count) {
    final bool selected = signatoryCount == count;
    return ChoiceChip(
      label: Text('$count Signatories', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      selected: selected,
      onSelected: enabled ? (_) => onSignatoryCountChanged(count) : null,
      selectedColor: const Color(0xFFEDE9FE),
      labelStyle: TextStyle(color: selected ? const Color(0xFF4F46E5) : const Color(0xFF475569)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: selected ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0)),
    );
  }

  List<UserModel> _peopleForSlot(int slotIndex) {
    final Set<String> usedElsewhere = <String>{
      for (int i = 0; i < slots.length; i++)
        if (i != slotIndex) slots[i].userId.trim(),
    }..remove('');
    return eligiblePeople.where((UserModel u) => !usedElsewhere.contains(u.userId.trim())).toList(growable: false);
  }
}

class _SignatorySlotEditor extends StatefulWidget {
  const _SignatorySlotEditor({
    super.key,
    required this.slotIndex,
    required this.slot,
    required this.eligiblePeople,
    required this.allEligiblePeople,
    required this.onChanged,
    required this.enabled,
  });

  final int slotIndex;
  final CertificateSignatorySlotDraft slot;
  final List<UserModel> eligiblePeople;
  final List<UserModel> allEligiblePeople;
  final ValueChanged<CertificateSignatorySlotDraft> onChanged;
  final bool enabled;

  @override
  State<_SignatorySlotEditor> createState() => _SignatorySlotEditorState();
}

class _SignatorySlotEditorState extends State<_SignatorySlotEditor> {
  late TextEditingController _nameController;
  late TextEditingController _designationController;
  bool _expanded = true;

  static const double _labelWidth = 118;
  static const TextStyle _inlineLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.slot.name);
    _designationController = TextEditingController(text: widget.slot.designation);
  }

  @override
  void didUpdateWidget(covariant _SignatorySlotEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot.name != widget.slot.name && _nameController.text != widget.slot.name) {
      _nameController.text = widget.slot.name;
    }
    if (oldWidget.slot.designation != widget.slot.designation &&
        _designationController.text != widget.slot.designation) {
      _designationController.text = widget.slot.designation;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  UserModel? get _selectedUser {
    final String id = widget.slot.userId.trim();
    if (id.isEmpty) return null;
    for (final UserModel u in widget.allEligiblePeople) {
      if (u.userId.trim() == id) return u;
    }
    return null;
  }

  String get _headerTitle {
    final String name = widget.slot.name.trim();
    final String person = name.isEmpty ? 'Not set' : name;
    return 'Signatory ${widget.slotIndex + 1} — $person';
  }

  @override
  Widget build(BuildContext context) {
    return MobileAccordionSection(
      title: _headerTitle,
      expanded: _expanded,
      onExpandedChanged: (bool value) => setState(() => _expanded = value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: _detailsLayout(context),
      ),
    );
  }

  Widget _detailsLayout(BuildContext context) {
    final bool sideBySide = !ResponsiveHelper.isMobile(context) && MediaQuery.sizeOf(context).width >= 520;
    final Widget left = _leftColumn();
    if (sideBySide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(flex: 7, child: left),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _signatureColumn(context, fillHeight: true)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        left,
        const SizedBox(height: 14),
        _signatureColumn(context, fillHeight: false),
      ],
    );
  }

  Widget _leftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _inlineField(
          label: 'Select person',
          field: HackzSelectField<UserModel?>(
            value: _selectedUser,
            hint: 'Optional',
            enabled: widget.enabled,
            compact: true,
            options: <UserModel?>[null, ...widget.eligiblePeople],
            labelBuilder: (UserModel? user) {
              if (user == null) return 'None';
              final String role = UserRoleLabels.labelFor(UserRole.fromCode(user.role));
              return '${user.displayName} · $role';
            },
            onChanged: (UserModel? user) {
              if (user == null) {
                widget.onChanged(widget.slot.copyWith(userId: ''));
                return;
              }
              widget.onChanged(
                widget.slot.copyWith(
                  userId: user.userId.trim(),
                  name: user.displayName,
                  designation: CertificateSignatoryPeopleLoader.defaultDesignation(user),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _inlineField(
          label: 'Name',
          field: TextField(
            enabled: widget.enabled,
            controller: _nameController,
            onChanged: (String v) => widget.onChanged(widget.slot.copyWith(name: v)),
            decoration: HackzInputDecoration.decorate(hintText: 'Name on certificate', compact: true),
          ),
        ),
        const SizedBox(height: 8),
        _inlineField(
          label: 'Designation',
          field: TextField(
            enabled: widget.enabled,
            controller: _designationController,
            onChanged: (String v) => widget.onChanged(widget.slot.copyWith(designation: v)),
            decoration: HackzInputDecoration.decorate(hintText: 'On certificate', compact: true),
          ),
        ),
      ],
    );
  }

  Widget _inlineField({required String label, required Widget field}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: _labelWidth,
          child: Text(label, style: _inlineLabelStyle),
        ),
        Expanded(child: field),
      ],
    );
  }

  Widget _signatureColumn(BuildContext context, {required bool fillHeight}) {
    final Uint8List? bytes = widget.slot.signatureBytes;
    final bool hasImage = bytes != null && bytes.isNotEmpty;

    final Widget preview = Container(
      width: double.infinity,
      height: fillHeight ? null : 112,
      constraints: fillHeight ? const BoxConstraints(minHeight: 112) : null,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: hasImage
          ? Image.memory(bytes, width: double.infinity, fit: BoxFit.contain)
          : const Text(
              'No signature uploaded',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('Signature', style: _inlineLabelStyle),
        const SizedBox(height: 6),
        if (fillHeight) Expanded(child: preview) else preview,
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.enabled ? () => _pickSignature(context) : null,
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: Text(hasImage ? 'Replace signature' : 'Upload signature'),
        ),
      ],
    );
  }

  Future<void> _pickSignature(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final Uint8List? data = result.files.first.bytes;
    if (data == null || data.isEmpty) return;
    final Uint8List processed = CertificateImageProcessing.prepareCertificateEmbed(data);
    widget.onChanged(widget.slot.copyWith(signatureBase64: base64Encode(processed)));
  }
}
