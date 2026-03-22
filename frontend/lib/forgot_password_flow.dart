import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    // Skip OTP and go straight to the Reset Password Page
    return ResetPasswordPage(
      onBack: widget.onBack,
      initialEmail: widget.prefilledEmail,
    );
  }
}
