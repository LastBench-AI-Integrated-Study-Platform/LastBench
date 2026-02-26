import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class OTPPage extends StatefulWidget {
  final void Function(String email, String otp) onNext;
  final VoidCallback onBack;
  final String? initialEmail;

  const OTPPage({
    super.key,
    required this.onNext,
    required this.onBack,
    this.initialEmail,
  });

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  bool otpSent = false;
  bool isLoading = false;
  String? message;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      emailController.text = widget.initialEmail!;
      // Auto-send OTP after first frame so widget tree is ready
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
    }
  }

  void _sendOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() => message = 'Email is required');
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final resp = await AuthService.requestOtp(email: email);
      final sent = resp['sent'] == true;
      final returnedOtp = resp['otp'] as String?;

      setState(() {
        otpSent = true;
        if (sent) {
          message = 'OTP sent to $email (check spam).';
        } else {
          message =
              'OTP could not be delivered. Check SMTP server settings on the backend.';
        }
      });

      // If backend returned OTP (DEV_SHOW_OTP enabled), show it in a dialog for local dev convenience
      if (returnedOtp != null && returnedOtp.isNotEmpty) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('DEV OTP (visible on this build)'),
            content: Text('OTP for $email: $returnedOtp'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _verifyOtp() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    if (email.isEmpty || otp.isEmpty) {
      setState(() => message = 'Email and OTP are required');
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      await AuthService.verifyOtp(email: email, otp: otp);
      widget.onNext(email, otp);
    } catch (e) {
      setState(() => message = 'Invalid OTP or error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Brand colors used in login page
  static const Color navy = Color(0xFF033F63);
  static const Color teal = Color(0xFF379392);

  @override
  Widget build(BuildContext context) {
    final messageColor =
        (message != null && message!.toLowerCase().contains('sent'))
        ? Colors.green
        : Colors.red;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: const [
                      Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF033F63),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enter your email to receive an OTP',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email input
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF033F63),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widget.initialEmail == null) ...[
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.mail, color: navy),
                                hintText: 'yourname@example.com',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            TextFormField(
                              controller: emailController,
                              readOnly: true,
                              enabled: false,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.mail, color: navy),
                                hintText: widget.initialEmail,
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // OTP input
                          if (otpSent) ...[
                            const Text(
                              'OTP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF033F63),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: otpController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock, color: navy),
                                hintText: 'Enter OTP',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (message != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (message!.toLowerCase().contains('sent'))
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                message!,
                                style: TextStyle(color: messageColor),
                              ),
                            ),

                          // Action button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : (otpSent ? _verifyOtp : _sendOtp),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      otpSent ? 'Verify OTP' : 'Send OTP',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Resend / Back
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (otpSent)
                                TextButton(
                                  onPressed: isLoading ? null : _sendOtp,
                                  child: const Text(
                                    'Resend OTP',
                                    style: TextStyle(color: Color(0xFF379392)),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),

                              TextButton(
                                onPressed: widget.onBack,
                                child: const Text(
                                  'Back to Login',
                                  style: TextStyle(color: Color(0xFF379392)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
