import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../exports/certificate/certificate_event_signatory_store.dart';
import '../../exports/certificate/certificate_signatory_people_loader.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../user/services/user_role_labels.dart';

class CertificateGenerationSignatoriesSection extends StatelessWidget {
  const CertificateGenerationSignatoriesSection({
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
          if (i > 0) const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Signatory ${widget.slotIndex + 1}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          HackzInputDecoration.fieldLabel('Select person'),
          const SizedBox(height: 4),
          HackzSelectField<UserModel?>(
            value: _selectedUser,
            hint: 'Optional — prefills fields below',
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
          const SizedBox(height: 10),
          HackzInputDecoration.fieldLabel('Name'),
          const SizedBox(height: 4),
          TextField(
            enabled: widget.enabled,
            controller: _nameController,
            onChanged: (String v) => widget.onChanged(widget.slot.copyWith(name: v)),
            decoration: HackzInputDecoration.decorate(hintText: 'Name on certificate', compact: true),
          ),
          const SizedBox(height: 10),
          HackzInputDecoration.fieldLabel('Certificate designation'),
          const SizedBox(height: 4),
          TextField(
            enabled: widget.enabled,
            controller: _designationController,
            onChanged: (String v) => widget.onChanged(widget.slot.copyWith(designation: v)),
            decoration: HackzInputDecoration.decorate(hintText: 'Designation on certificate', compact: true),
          ),
          const SizedBox(height: 10),
          _SignatureRow(slot: widget.slot, enabled: widget.enabled, onChanged: widget.onChanged),
        ],
      ),
    );
  }
}

class _SignatureRow extends StatelessWidget {
  const _SignatureRow({
    required this.slot,
    required this.onChanged,
    required this.enabled,
  });

  final CertificateSignatorySlotDraft slot;
  final ValueChanged<CertificateSignatorySlotDraft> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = slot.signatureBytes;
    final bool hasImage = bytes != null && bytes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HackzInputDecoration.fieldLabel('Signature'),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: enabled ? () => _pick(context) : null,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(hasImage ? 'Replace signature' : 'Upload signature'),
            ),
            if (hasImage)
              Container(
                width: 72,
                height: 36,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final Uint8List? data = result.files.first.bytes;
    if (data == null || data.isEmpty) return;
    onChanged(slot.copyWith(signatureBase64: base64Encode(data)));
  }
}
