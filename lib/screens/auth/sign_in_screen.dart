import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/enums/account_workspace_phase.dart';
import '../../models/user_model.dart';
import '../common/auth_page_layout.dart';
import '../common/phone_number_field.dart';
import '../../utils/auth_utils.dart';
import '../../utils/common_helpers.dart';
import 'otp_screen.dart';
import 'sign_up_screen.dart';
import '../../widgets/signup/account_status_workspace.dart';
import '../../models/enums/user_status.dart';
import '../../utils/firestore_utils.dart';
import 'auth_gate.dart';
import 'landing_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtpAndOpen(String phone) async {
    await AuthUtils.sendOtp(
      phone: phone,
      onCodeSent: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phone: phone,
              navigateToAuthGateOnVerified: false,
              onVerified: () => _handlePostOtpRouting(phone),
            ),
          ),
        );
      },
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
            FirebaseAuth.instance.signOut();
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
    final user = await FirestoreUtils.fetchUserByPhone(normalizedPhone);
    if (!mounted) return;

    if (user == null) {
      // Whitelisted SysAdmin may have no hkzUsers row yet; resolver creates it — do not sign out or send to signup.
      final whitelist = await AuthUtils.checkWhitelist(normalizedPhone);
      if (whitelist != null) {
        if (!mounted) return;
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
        return;
      }

      await FirebaseAuth.instance.signOut();
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

  Future<void> _onSignIn() async {
    if (!isValidPhoneInput(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final phone = normalizePhoneE164(_phoneController.text);
      await _sendOtpAndOpen(phone);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Welcome Back!',
      subtitle: 'Sign in to continue your journey\nwith HackZ',
      formContent: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD6D9F0)),
            ),
            child: PhoneNumberField(
              controller: _phoneController,
              autofocus: true,
              onSubmitted: (_) => _onSignIn(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_android_outlined),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "All users verify with OTP, then we'll route by account status",
            style: TextStyle(color: Color(0xFF595E80)),
          ),
        ],
      ),
      nextLabel: 'Next',
      onNext: _onSignIn,
      onCancel: () => Navigator.of(context).maybePop(),
      isLoading: _isLoading,
      extraContent: _FeatureRow(),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: const Color(0xFF5A5F87), size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF515777),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4D8F1)),
      ),
      child: Row(
        children: <Widget>[
          item(Icons.shield_outlined, 'Secure\nAccess'),
          item(Icons.groups_outlined, 'Role Based\nDashboards'),
          item(Icons.auto_awesome_outlined, 'Smart\nCollaboration'),
          item(Icons.fact_check_outlined, 'Approval\nWorkflow'),
        ],
      ),
    );
  }
}
