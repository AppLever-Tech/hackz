import 'package:flutter/material.dart';

import '../../models/organization_model.dart';
import '../../models/enums/organization_type.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/org_code_generator.dart';
import '../common/read_only_field.dart';

class CreateOrganizationDialogForm extends StatefulWidget {
  const CreateOrganizationDialogForm({
    super.key,
    this.organizationType,
    this.asDialog = false,
  });

  /// When `null` and [asDialog] is true, the form shows a type selector (unified labels).
  /// When non-null, legacy labels and no type dropdown.
  final OrganizationType? organizationType;
  final bool asDialog;

  @override
  State<CreateOrganizationDialogForm> createState() => _CreateOrganizationDialogFormState();
}

class _CreateOrganizationDialogFormState extends State<CreateOrganizationDialogForm> {
  static const double _pairFieldHeight = 50;
  static const TextStyle _pairHeaderStyle = TextStyle(fontWeight: FontWeight.w600);

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressController = TextEditingController();
  bool _busy = false;
  bool _overrideCode = false;
  int _codeGenerationEpoch = 0;
  late OrganizationType _selectedType;

  bool get _unifiedDialog => widget.asDialog && widget.organizationType == null;

  String get _legacyDisplayType => (widget.organizationType ?? OrganizationType.college).displayName;

  OrganizationType get _effectiveType => widget.organizationType ?? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.organizationType ?? OrganizationType.college;
    _nameController.addListener(_onOrganizationNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onOrganizationNameChanged);
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _onOrganizationNameChanged() async {
    if (_overrideCode || _busy) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (_codeController.text.isNotEmpty) {
        setState(() => _codeController.text = '');
      }
      return;
    }
    final epoch = ++_codeGenerationEpoch;
    final generated = await generateOrganizationCodeFromName(
      name,
      _effectiveType,
    );
    if (!mounted || epoch != _codeGenerationEpoch || _overrideCode) return;
    if (_codeController.text != generated) {
      setState(() => _codeController.text = generated);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    final address = _addressController.text.trim();
    if (name.isEmpty || code.isEmpty || address.isEmpty) {
      _toast(_unifiedDialog ? 'Please fill all organization details' : 'Please fill all $_legacyDisplayType details');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirestoreUtils.upsertOrganization(
        OrganizationModel(
          id: '',
          name: name,
          code: code,
          type: _effectiveType,
          address: address,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _toast('Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  InputDecoration _fieldDecoration(
    String hint, {
    bool readOnly = false,
    String? helperText,
    bool dense = false,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helperText,
      isDense: dense,
      filled: true,
      fillColor: readOnly ? const Color(0xFFF2F0F8) : Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: dense ? 12 : 14,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: readOnly ? const Color(0xFFD2C8EC) : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
      ),
    );
  }

  ButtonStyle _compactButtonStyle() {
    return FilledButton.styleFrom(
      minimumSize: const Size(88, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  ButtonStyle _compactOutlineButtonStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(88, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  Widget _codeField({bool inlineWithType = false}) {
    final bool dense = inlineWithType;
    return _overrideCode
        ? TextField(
            controller: _codeController,
            readOnly: false,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            onChanged: (value) {
              final normalized = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
              if (normalized == value) return;
              _codeController.value = TextEditingValue(
                text: normalized,
                selection: TextSelection.collapsed(offset: normalized.length),
              );
            },
            decoration: _fieldDecoration(
              'Auto-generated code',
              helperText: inlineWithType ? null : 'Override enabled before save. Code is locked after creation.',
              dense: dense,
            ).copyWith(
              suffixIcon: IconButton(
                tooltip: 'Disable override',
                onPressed: () {
                  setState(() => _overrideCode = false);
                  _onOrganizationNameChanged();
                },
                icon: const Icon(
                  Icons.lock_open_rounded,
                  color: Color(0xFF6A38FF),
                ),
              ),
            ),
          )
        : ReadOnlyField(
            value: _codeController.text,
            hintText: 'Auto-generated code',
            helperText: inlineWithType ? null : 'Auto-generated. Tap lock to override before save.',
            compact: inlineWithType,
            suffixIcon: IconButton(
              tooltip: 'Override code',
              onPressed: () => setState(() => _overrideCode = true),
              icon: const Icon(
                Icons.lock_rounded,
                color: Color(0xFF6A38FF),
              ),
            ),
          );
  }

  Widget _typeDropdown({required double width}) {
    return DropdownMenu<OrganizationType>(
      key: ValueKey<OrganizationType>(_selectedType),
      initialSelection: _selectedType,
      enableFilter: false,
      requestFocusOnTap: true,
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
        ),
      ),
      width: width,
      dropdownMenuEntries: OrganizationType.values
          .map(
            (OrganizationType t) => DropdownMenuEntry<OrganizationType>(
              value: t,
              label: t.displayName,
            ),
          )
          .toList(growable: false),
      onSelected: (OrganizationType? t) {
        if (t == null) return;
        setState(() => _selectedType = t);
        _onOrganizationNameChanged();
      },
    );
  }

  Widget _pairFieldShell(Widget child) {
    return SizedBox(
      height: _pairFieldHeight,
      width: double.infinity,
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }

  Widget _formBody() {
    final bool unified = _unifiedDialog;
    final String title = unified ? 'New Organization' : 'New ${_legacyDisplayType.toLowerCase()}';
    final String nameLabel = unified ? 'Organization name' : '$_legacyDisplayType name';
    final String nameHint = unified ? 'Enter organization name' : 'Enter $_legacyDisplayType name';
    final String codeLabel = unified ? 'Organization code' : '$_legacyDisplayType code';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: widget.asDialog ? MainAxisSize.min : MainAxisSize.max,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.apartment_rounded, color: Color(0xFF6A38FF), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(nameLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: _fieldDecoration(nameHint),
        ),
        const SizedBox(height: 16),
        if (unified) ...<Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: Text('Organization code', style: _pairHeaderStyle)),
              const SizedBox(width: 12),
              const Expanded(child: Text('Type', style: _pairHeaderStyle)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _pairFieldShell(
                  _codeField(inlineWithType: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pairFieldShell(
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints c) {
                      return _typeDropdown(width: c.maxWidth);
                    },
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _overrideCode
                  ? 'Override enabled before save. Code is locked after creation.'
                  : 'Auto-generated. Tap lock to override before save.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
            ),
          ),
        ] else ...<Widget>[
          Text(codeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _codeField(),
        ],
        const SizedBox(height: 16),
        const Text('Address', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          maxLines: 3,
          minLines: 3,
          decoration: _fieldDecoration('Street, city, state, PIN...'),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            OutlinedButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              style: _compactOutlineButtonStyle(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: _compactButtonStyle(),
              child: Text(_busy ? 'Creating...' : 'Create'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _formBody();
    if (widget.asDialog) return body;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: body,
      ),
    );
  }
}
