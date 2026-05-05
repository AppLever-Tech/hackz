import 'package:flutter/material.dart';

import '../common/auth_page_layout.dart';
import '../../utils/auth_utils.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/role_utils.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter complete OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthUtils.verifyOtp(_otpValue);
      final user = await FirestoreUtils.fetchUserByPhone(widget.phone);

      if (!mounted || user == null) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleUtils.routeForRole(user)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: $e')),
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
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD0D5EC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD0D5EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6A38FF), width: 1.6),
              ),
            ),
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
