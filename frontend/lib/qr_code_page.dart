import 'package:flutter/material.dart';

class QRCodePage extends StatelessWidget {
  /// Placeholder page for QR flow that was converted to OTP
  final void Function(String sessionId) onNext;
  final VoidCallback onBack;

  const QRCodePage({super.key, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'QR flow removed',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Password reset now uses OTP sent to your email. Please go back and choose "Forgot password" to continue.',
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onBack,
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
