import 'package:flutter/material.dart';

import '../../../shared/feedback/feedback.dart';
import '../../../screens/common/auth_page_layout.dart';
import 'auth_gate.dart';
import '../../../core/theme/auth_theme.dart';
import '../services/auth_utils.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    this.onVerified,
    this.navigateToAuthGateOnVerified = true,
  });

  final String phone;
  final Future<void> Function()? onVerified;
  final bool navigateToAuthGateOnVerified;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _focusNodes;
  bool _isLoading = false;
  bool _isAutoSubmitting = false;

  String get _otpValue =>
      _otpControllers.map((TextEditingController c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _otpControllers = List<TextEditingController>.generate(
      _otpLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List<FocusNode>.generate(
      _otpLength,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpValue.length != _otpLength) {
      FeedbackService.showWarning(
        context,
        title: 'OTP required',
        message: 'Enter complete OTP',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthUtils.verifyOtp(_otpValue);
      if (widget.onVerified != null) {
        await widget.onVerified!();
      }
      if (!widget.navigateToAuthGateOnVerified) return;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(
        context,
        title: 'OTP verification failed',
        message: '$e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _maybeAutoSubmit() async {
    if (_isAutoSubmitting || _isLoading) return;
    if (_otpValue.length != _otpLength) return;
    _isAutoSubmitting = true;
    await _verifyOtp();
    _isAutoSubmitting = false;
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    _maybeAutoSubmit();
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(_otpLength, (int index) {
        return SizedBox(
          width: 44,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            autofocus: index == 0,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            textInputAction:
                index == _otpLength - 1 ? TextInputAction.done : TextInputAction.next,
            decoration: AuthTheme.otpDigitField(),
            onChanged: (String value) => _onOtpDigitChanged(index, value),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: 'Verify OTP',
      subtitle: 'Enter the OTP sent to ${widget.phone}',
      formContent: _buildOtpBoxes(),
      nextLabel: 'Next',
      onNext: _verifyOtp,
      onCancel: () => Navigator.of(context).maybePop(),
      isLoading: _isLoading,
    );
  }
}
