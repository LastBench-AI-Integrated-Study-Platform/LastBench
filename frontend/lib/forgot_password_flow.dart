import 'package:flutter/material.dart';
import 'qr_code_page.dart';
import 'reset_password_page.dart';

class ForgotPasswordFlow extends StatefulWidget {
  final VoidCallback onBack;

  const ForgotPasswordFlow({super.key, required this.onBack});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  bool showResetPage = false;

  void goToReset() {
    setState(() => showResetPage = true);
  }

  void goBackToQR() {
    setState(() => showResetPage = false);
  }

  @override
  Widget build(BuildContext context) {
    return showResetPage
        ? ResetPasswordPage(onBack: goBackToQR)
        : QRCodePage(onNext: goToReset, onBack: widget.onBack);
  }
}
