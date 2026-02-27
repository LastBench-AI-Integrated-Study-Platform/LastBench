import 'package:flutter/material.dart';
import 'otp_page.dart';
import 'reset_password_page.dart';

class ForgotPasswordFlow extends StatefulWidget {
  final VoidCallback onBack;
  final String? prefilledEmail;

  const ForgotPasswordFlow({
    super.key,
    required this.onBack,
    this.prefilledEmail,
  });

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  bool showResetPage = false;
  String? _email;
  String? _otp;

  void goToReset(String email, String otp) {
    setState(() {
      _email = email;
      _otp = otp;
      showResetPage = true;
    });
  }

  void goBackToOTP() {
    setState(() {
      showResetPage = false;
      _email = null;
      _otp = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return showResetPage
        ? ResetPasswordPage(
            onBack: goBackToOTP,
            initialEmail: _email,
            initialOtp: _otp,
          )
        : OTPPage(onNext: goToReset, onBack: widget.onBack);
  }
}
