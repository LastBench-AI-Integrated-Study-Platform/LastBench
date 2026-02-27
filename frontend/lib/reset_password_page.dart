import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final VoidCallback onBack;
  final String? initialEmail;
  final String? initialOtp;

  const ResetPasswordPage({
    super.key,
    required this.onBack,
    this.initialEmail,
    this.initialOtp,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool showPassword = false;
  bool showConfirm = false;
  bool isSubmitting = false;
  String? message;

  // Brand colors
  static const Color navy = Color(0xFF033F63);
  static const Color teal = Color(0xFF379392);

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null)
      usernameController.text = widget.initialEmail!;
    if (widget.initialOtp != null) otpController.text = widget.initialOtp!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔹 Header
                      const Center(
                        child: Column(
                          children: [
                            Text(
                              "Create New Password",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: navy,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Secure your account with a new password",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// Username
                      _label("Email"),
                      _inputField(
                        controller: usernameController,
                        icon: Icons.person,
                        hint: "Enter your email",
                        readOnly: widget.initialEmail != null,
                      ),

                      const SizedBox(height: 20),

                      _label("OTP"),
                      _inputField(
                        controller: otpController,
                        icon: Icons.shield,
                        hint: "Enter OTP sent to email",
                      ),

                      const SizedBox(height: 20),

                      /// New Password
                      _label("New Password"),
                      _inputField(
                        controller: passwordController,
                        icon: Icons.lock,
                        hint: "Enter new password",
                        obscure: !showPassword,
                        toggle: () {
                          setState(() => showPassword = !showPassword);
                        },
                        showToggle: true,
                      ),

                      const SizedBox(height: 20),

                      /// Confirm Password
                      _label("Confirm Password"),
                      _inputField(
                        controller: confirmController,
                        icon: Icons.lock_outline,
                        hint: "Re-enter password",
                        obscure: !showConfirm,
                        toggle: () {
                          setState(() => showConfirm = !showConfirm);
                        },
                        showToggle: true,
                      ),

                      const SizedBox(height: 30),

                      /// Reset Button
                      if (message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            message!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
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
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate())
                                    return;
                                  final email = usernameController.text.trim();
                                  final otp = otpController.text.trim();
                                  final pw = passwordController.text.trim();
                                  final conf = confirmController.text.trim();
                                  if (pw != conf) {
                                    setState(() {
                                      message = 'Passwords do not match';
                                    });
                                    return;
                                  }

                                  if (otp.isEmpty) {
                                    setState(() {
                                      message = 'OTP is required';
                                    });
                                    return;
                                  }

                                  setState(() {
                                    isSubmitting = true;
                                    message = null;
                                  });

                                  try {
                                    await AuthService.resetPasswordWithOtp(
                                      email: email,
                                      otp: otp,
                                      newPassword: pw,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Password reset successful',
                                        ),
                                      ),
                                    );
                                    widget.onBack();
                                  } catch (e) {
                                    setState(() {
                                      message = 'Error: $e';
                                    });
                                  } finally {
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Reset Password",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Back
                      Center(
                        child: TextButton(
                          onPressed: widget.onBack,
                          child: const Text(
                            "Back",
                            style: TextStyle(color: teal),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Helpers
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, color: navy),
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    bool showToggle = false,
    VoidCallback? toggle,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      readOnly: readOnly,
      enabled: !readOnly,
      validator: (v) => v == null || v.isEmpty ? "Required field" : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: navy),
        suffixIcon: showToggle
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: navy,
                ),
                onPressed: toggle,
              )
            : null,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
