import 'package:flutter/material.dart';

import '../../models/enums/organization_type.dart';
import '../../models/enums/user_status.dart';
import '../../models/department_model.dart';
import '../../models/user_model.dart';
import '../common/auth_page_layout.dart';
import '../common/email_field.dart';
import '../common/phone_number_field.dart';
import '../../utils/common_helpers.dart';
import '../../utils/firestore_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.phone = ''});

  final String phone;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _accessCodeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text =
        widget.phone.replaceFirst('+91', '').replaceAll(RegExp(r'\D'), '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        !isValidEmailInput(_emailController.text) ||
        !isValidPhoneInput(_phoneController.text) ||
        _accessCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final String phone = normalizePhoneE164(_phoneController.text);
      final existingUser = await FirestoreUtils.fetchUserByPhone(phone);
      if (existingUser != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User already registered for this phone.')),
        );
        return;
      }

      final rawCode = _accessCodeController.text.trim();
      if (!RegExp(r'^\d{6}$').hasMatch(rawCode)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access code must be a 6-digit code.')),
        );
        return;
      }
      final codeData = await FirestoreUtils.fetchInviteCode(rawCode);
      if (codeData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Access Code')),
        );
        return;
      }

      final user = UserModel(
        userId: '',
        phone: phone,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        role: (codeData['role'] as String?) ?? 'STU',
        orgType: OrganizationType.fromFirestoreValue(codeData['orgType']),
        orgId: (codeData['orgId'] as String?) ?? '',
        department: (codeData['department'] as String?) ?? '',
        departmentCode: DepartmentModel.resolveCode((codeData['departmentCode'] as String?)?.trim().isNotEmpty == true
            ? (codeData['departmentCode'] as String)
            : ((codeData['department'] as String?) ?? '')),
        status: UserStatus.pending,
        createdAt: DateTime.now(),
      );

      await FirestoreUtils.createUser(user);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration submitted. Await admin approval.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Sign Up',
      formContent: Column(
        children: <Widget>[
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              hintText: 'First Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              hintText: 'Last Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          EmailField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          PhoneNumberField(
            controller: _phoneController,
            decoration: const InputDecoration(
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone_android_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _accessCodeController,
            decoration: const InputDecoration(
              hintText: 'Access Code',
              prefixIcon: Icon(Icons.key_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      nextLabel: 'Next',
      onNext: _submit,
      onCancel: () => Navigator.of(context).maybePop(),
      isLoading: _isSubmitting,
    );
  }
}
