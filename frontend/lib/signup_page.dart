import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  // 🎨 Colors
  static const Color navy = Color(0xFF0B2E3C);
  static const Color teal = Color(0xFF379392);
  static const Color hintGrey = Color(0xFF9AA6AC);
  static const Color fieldBg = Color(0xFFF5F7F8);

  // 🔐 Password Validation
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Include at least one uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "Include at least one lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Include at least one number";
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}_-|<>]').hasMatch(value)) {
      return "Include at least one special character";
    }
    return null;
  }

  void submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final msg = await AuthService.signup(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        exam: "Other",
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // 🔙 Back
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
  Navigator.pushNamed(context, '/landing');
},

                    icon: const Icon(Icons.arrow_back, color: navy),
                    label: const Text(
                      "Back",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: navy,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 Header
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                    children: [
                      TextSpan(
                        text: "Join ",
                        style: TextStyle(color: navy),
                      ),
                      TextSpan(
                        text: "Last Bench",
                        style: TextStyle(color: teal),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  "Start your journey from the last bench to the top rank",
                  style: TextStyle(
                    fontSize: 14,
                    color: hintGrey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // 🔹 Card
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label("Full Name"),
                          const SizedBox(height: 10),
                          _textField(
                            controller: nameController,
                            icon: Icons.person_outline,
                            hint: "Enter your full name",
                          ),

                          const SizedBox(height: 16),

                          _label("Email Address"),
                          const SizedBox(height: 10),
                          _textField(
                            controller: emailController,
                            icon: Icons.mail_outline,
                            hint: "yourname@example.com",
                            keyboard: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 16),

                          _label("Password"),
                          const SizedBox(height: 10),
                          _passwordField(
                            controller: passwordController,
                            hint: "Create a strong password",
                            visible: showPassword,
                            toggle: () =>
                                setState(() => showPassword = !showPassword),
                            validator: validatePassword,
                          ),

                          const SizedBox(height: 16),

                          _label("Confirm Password"),
                          const SizedBox(height: 10),
                          _passwordField(
                            controller: confirmPasswordController,
                            hint: "Re-enter your password",
                            visible: showConfirmPassword,
                            toggle: () => setState(() =>
                                showConfirmPassword = !showConfirmPassword),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please confirm your password";
                              }
                              if (value != passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading ? null : submitSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: teal,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                isLoading
                                    ? "Creating Account..."
                                    : "Create Account",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 🔹 Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: hintGrey,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text(
                        "Sign in",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: teal,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const Text(
                  "\"Your rank doesn't define your potential. Join us.\"",
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: hintGrey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- UI Helpers ----------------

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: navy,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "This field is required";
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: hintGrey),
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: hintGrey,
        ),
        filled: true,
        fillColor: fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.lock_outline, color: hintGrey),
        suffixIcon: IconButton(
          icon: Icon(
            visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: hintGrey,
          ),
          onPressed: toggle,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: hintGrey,
        ),
        filled: true,
        fillColor: fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
