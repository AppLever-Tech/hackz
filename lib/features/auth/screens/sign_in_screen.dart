import 'package:flutter/material.dart';

import '../models/enums/account_workspace_phase.dart';
import '../../user/models/user_model.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/loading/hkz_loading_overlay.dart';
import '../widgets/auth_page_layout.dart';
import '../../../core/ui/inputs/phone_number_field.dart';
import '../../../core/theme/auth_theme.dart';
import '../widgets/auth_feature_strip.dart';
import '../widgets/organisation_code_field.dart';
import '../services/auth_utils.dart';
import '../../../utils/common_helpers.dart';
import 'otp_screen.dart';
import 'sign_up_screen.dart';
import '../widgets/signup/account_status_workspace.dart';
import '../../user/models/enums/user_status.dart';
import '../../../utils/firestore_utils.dart';
import 'auth_gate.dart';
import 'landing_screen.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';
import 'package:hackz/core/firebase/last_organisation_code_store.dart';
import 'package:hackz/core/firebase/organisation_code.dart';
import 'package:hackz/core/firebase/tenant_connection_exception.dart';
import 'package:hackz/core/firebase/tenant_firebase.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _orgCodeController = TextEditingController();
  final FocusNode _orgCodeFocus = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefillLastOrganisationCode();
  }

  Future<void> _prefillLastOrganisationCode() async {
    final String? lastCode = await LastOrganisationCodeStore.read();
    if (!mounted || lastCode == null || _orgCodeController.text.trim().isNotEmpty) {
      return;
    }
    _orgCodeController.text = lastCode;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _orgCodeController.dispose();
    _orgCodeFocus.dispose();
    super.dispose();
  }

  void _openOtp(String phone) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpScreen(
          phone: phone,
          navigateToAuthGateOnVerified: false,
          onVerified: () => _handlePostOtpRouting(phone),
        ),
      ),
    );
  }

  Future<void> _openStatusWorkspace({
    required UserModel user,
    required AccountWorkspacePhase phase,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => AccountStatusWorkspace(
          user: user,
          phase: phase,
          onSignOut: () {
            TenantFirebase.releaseSession();
            Navigator.of(routeContext).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LandingScreen()),
              (_) => false,
            );
          },
        ),
      ),
    );
  }

  Future<void> _handlePostOtpRouting(String phone) async {
    final normalizedPhone = normalizePhoneE164(phone);
    // Profile lookup is on the resolved tenant Firestore only — never Control Plane.
    final user = await FirestoreUtils.fetchUserByPhone(normalizedPhone);
    if (!mounted) return;

    if (user == null) {
      final whitelist = await AuthUtils.checkWhitelist(normalizedPhone);
      if (whitelist != null) {
        if (!mounted) return;
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
        return;
      }

      // Keep the tenant bound so Sign Up OTPs against the same workspace.
      await HackzFirebase.current.auth.signOut();
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => SignUpScreen(phone: normalizedPhone),
        ),
        (_) => false,
      );
      return;
    }

    if (user.status == UserStatus.active) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
      return;
    }

    await _openStatusWorkspace(
      user: user,
      phase: user.status.toWorkspacePhase,
    );
  }

  Future<void> _onContinue() async {
    final String? organisationCode = OrganisationCode.tryParse(_orgCodeController.text);
    if (organisationCode == null) {
      FeedbackService.showWarning(
        context,
        title: 'Invalid organisation code',
        message: 'Enter a valid organisation code (HKZ-XXXXXX).',
      );
      return;
    }

    if (!isValidPhoneInput(_phoneController.text)) {
      FeedbackService.showWarning(
        context,
        title: 'Invalid phone number',
        message: 'Enter a valid 10-digit phone number',
      );
      return;
    }

    final String phone = normalizePhoneE164(_phoneController.text);
    setState(() => _isLoading = true);
    bool connected = false;
    try {
      HkzLoadingOverlay.show(
        context,
        title: 'Signing in',
        message: 'Connecting to your organisation...',
      );
      await TenantFirebase.connect(organisationCode);
      connected = true;
      await LastOrganisationCodeStore.save(organisationCode);
      HkzLoadingOverlay.hide();
      await AuthUtils.sendOtp(phone: phone, onCodeSent: () {});
      if (!mounted) return;
      if (HackzFirebase.current.auth.currentUser != null) {
        await _handlePostOtpRouting(phone);
        return;
      }
      _openOtp(phone);
    } on TenantConnectionException catch (e) {
      HkzLoadingOverlay.hide();
      if (!mounted) return;
      FeedbackService.showError(
        context,
        title: 'Unable to continue',
        message: e.message,
      );
    } catch (e) {
      HkzLoadingOverlay.hide();
      if (connected &&
          HackzFirebase.isTenantBound &&
          HackzFirebase.current.auth.currentUser == null) {
        await TenantFirebase.disconnect();
      }
      if (!mounted) return;
      FeedbackService.showError(
        context,
        title: 'Sign in failed',
        message: '$e',
      );
    } finally {
      HkzLoadingOverlay.hide();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Sign in',
      subtitle: 'Enter your mobile number and organisation code',
      formContent: Column(
        children: <Widget>[
          PhoneNumberField(
            controller: _phoneController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _orgCodeFocus.requestFocus(),
            decoration: AuthTheme.filledField(
              prefixIcon: const Icon(Icons.phone_android_outlined),
            ),
          ),
          const SizedBox(height: 12),
          OrganisationCodeField(
            controller: _orgCodeController,
            focusNode: _orgCodeFocus,
            onSubmitted: (_) => _onContinue(),
          ),
          const SizedBox(height: 10),
          const Text(
            'We’ll send a verification code to this number',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF595E80)),
          ),
        ],
      ),
      nextLabel: 'Continue',
      onNext: _onContinue,
      onCancel: () => Navigator.of(context).maybePop(),
      isLoading: _isLoading,
      extraContent: const AuthFeatureStrip(),
    );
  }
}
