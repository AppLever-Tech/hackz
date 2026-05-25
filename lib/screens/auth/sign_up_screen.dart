import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/enums/organization_type.dart';
import '../../models/enums/account_workspace_phase.dart';
import '../../models/enums/user_status.dart';
import '../../models/department_model.dart';
import '../../models/user_model.dart';
import '../../constants/app_icons.dart';
import '../common/auth_page_layout.dart';
import '../../core/theme/auth_theme.dart';
import '../common/email_field.dart';
import '../common/phone_number_field.dart';
import 'otp_screen.dart';
import 'landing_screen.dart';
import '../../utils/auth_utils.dart';
import '../../utils/common_helpers.dart';
import '../../utils/firestore_utils.dart';
import '../../widgets/signup/account_status_workspace.dart';

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
  late final List<TextEditingController> _accessCodeControllers;
  late final List<FocusNode> _accessCodeFocusNodes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text =
        widget.phone.replaceFirst('+91', '').replaceAll(RegExp(r'\D'), '');
    _accessCodeControllers = List<TextEditingController>.generate(
      6,
      (_) => TextEditingController(),
    );
    _accessCodeFocusNodes = List<FocusNode>.generate(
      6,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (final c in _accessCodeControllers) {
      c.dispose();
    }
    for (final n in _accessCodeFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _accessCodeRaw => _accessCodeControllers.map((c) => c.text).join();

  Future<void> _cancelToLanding() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  void _onAccessCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < _accessCodeControllers.length - 1) {
      _accessCodeFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _accessCodeFocusNodes[index - 1].requestFocus();
    }
  }

  Widget _buildAccessCodeFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(_accessCodeControllers.length + 1, (int uiIndex) {
        if (uiIndex == 3) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          );
        }
        final int fieldIndex = uiIndex > 3 ? uiIndex - 1 : uiIndex;
        return SizedBox(
          width: 42,
          child: TextField(
            controller: _accessCodeControllers[fieldIndex],
            focusNode: _accessCodeFocusNodes[fieldIndex],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
              ),
            ),
            onChanged: (value) => _onAccessCodeChanged(fieldIndex, value),
          ),
        );
      }),
    );
  }

  Future<void> _submit() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        !isValidEmailInput(_emailController.text) ||
        !isValidPhoneInput(_phoneController.text) ||
        _accessCodeRaw.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final String phone = normalizePhoneE164(_phoneController.text);
      final rawCode = _accessCodeRaw.trim();
      if (!RegExp(r'^\d{6}$').hasMatch(rawCode)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access code must be a 6-digit code.')),
        );
        return;
      }
      await AuthUtils.sendOtp(
        phone: phone,
        onCodeSent: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                phone: phone,
                onVerified: () async {
                  final existingUser = await FirestoreUtils.fetchUserByPhone(phone);
                  if (existingUser != null) {
                    throw StateError('User already registered for this phone.');
                  }

                  final codeData = await FirestoreUtils.fetchInviteCode(rawCode);
                  if (codeData == null) {
                    throw StateError('Invalid Access Code');
                  }

                  final user = UserModel(
                    userId: '',
                    phone: phone,
                    firstName: _firstNameController.text.trim(),
                    lastName: _lastNameController.text.trim(),
                    email: _emailController.text.trim(),
                    role: '',
                    orgType: OrganizationType.fromFirestoreValue(codeData['orgType']),
                    orgId: (codeData['orgId'] as String?) ?? '',
                    department: (codeData['department'] as String?) ?? '',
                    departmentCode: DepartmentModel.resolveCode(
                      (codeData['departmentCode'] as String?)?.trim().isNotEmpty == true
                          ? (codeData['departmentCode'] as String)
                          : ((codeData['department'] as String?) ?? ''),
                    ),
                    status: UserStatus.pendingApproval,
                    createdAt: DateTime.now(),
                  );

                  final userId = await FirestoreUtils.createUser(user);
                  if (!mounted) return;
                  final createdUser = user.copyWith(userId: userId);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (routeContext) => AccountStatusWorkspace(
                        user: createdUser,
                        phase: AccountWorkspacePhase.pendingApproval,
                        onSignOut: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.of(routeContext).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LandingScreen()),
                            (_) => false,
                          );
                        },
                      ),
                    ),
                    (_) => false,
                  );
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Registration submitted. Use Sign In anytime to track approval status.'),
                    ),
                  );
                },
                navigateToAuthGateOnVerified: false,
              ),
            ),
          );
        },
      );
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
            decoration: AuthTheme.filledField(
              hintText: 'First Name',
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastNameController,
            decoration: AuthTheme.filledField(
              hintText: 'Last Name',
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          EmailField(
            controller: _emailController,
            decoration: AuthTheme.filledField(
              hintText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          PhoneNumberField(
            controller: _phoneController,
            decoration: AuthTheme.filledField(
              hintText: 'Enter your phone number',
              prefixIcon: const Icon(Icons.phone_android_outlined),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: <Widget>[
              Icon(AppIcons.key, size: 18, color: AuthTheme.label),
              SizedBox(width: 8),
              Text(
                'Access Code',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AuthTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAccessCodeFields(),
        ],
      ),
      nextLabel: 'Next',
      onNext: _submit,
      onCancel: _cancelToLanding,
      isLoading: _isSubmitting,
    );
  }
}
