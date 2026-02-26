import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'last_bench_home.dart';
import 'forgot_password_flow.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool showPassword = false;
  bool rememberMe = false;
  bool isLoading = false;

  // 🎨 SAME colors as Signup page
  static const Color navy = Color(0xFF0B2E3C);
  static const Color teal = Color(0xFF379392);
  static const Color hintGrey = Color(0xFF9AA6AC);
  static const Color fieldBg = Color(0xFFF5F7F8);

  void submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await AuthService.login(
        email: emailController.text,
        password: passwordController.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LastBenchHome()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email or password")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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

                const SizedBox(height: 56),

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
                        text: "Welcome to ",
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
                  "Sign in to continue your study journey",
                  style: TextStyle(fontSize: 14, color: hintGrey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // 🔹 Card (SAME as Signup)
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
                            hint: "Enter your password",
                            visible: showPassword,
                            toggle: () =>
                                setState(() => showPassword = !showPassword),
                          ),

                          const SizedBox(height: 10),

                          // Remember + Forgot
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Forgot password?",
                                  style: TextStyle(fontSize: 13, color: teal),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: teal,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                isLoading ? "Signing In..." : "Sign In",
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

                // 🔹 Signup link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "New to Last Bench? ",
                      style: TextStyle(fontSize: 14, color: hintGrey),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/signup'),
                      child: const Text(
                        "Create an account",
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
                  "\"Back benchers welcome. Top ranks guaranteed.\"",
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
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: hintGrey),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: hintGrey),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "This field is required";
        }
        return null;
      },
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback toggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: hintGrey),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: hintGrey,
          ),
          onPressed: toggle,
        ),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: hintGrey),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.length < 6) {
          return "Password must be at least 6 characters";
        }
        return null;
      },
    );
  }
}
