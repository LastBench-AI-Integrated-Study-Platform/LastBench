import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
=======
>>>>>>> Stashed changes
import '../services/auth_service.dart';
import '../deadline_provider.dart';
import 'last_bench_home.dart';
import 'forgot_password_flow.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
<<<<<<< Updated upstream
=======

>>>>>>> Stashed changes
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool showPassword = false;
  bool rememberMe = false;
  bool isLoading = false;
  String? error;

<<<<<<< Updated upstream
  static const Color navy = Color(0xFF033F63);
  static const Color teal = Color(0xFF379392);
=======
  // 🎨 Exact design colors
  static const Color navy = Color(0xFF0F2E3C);
  static const Color teal = Color(0xFF3A8D86);
  static const Color hintGrey = Color(0xFF9FB0B7);
  static const Color borderGrey = Color(0xFFE6ECEF);
  static const Color fieldBg = Color(0xFFFBFDFE);
>>>>>>> Stashed changes

  void submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      error = null;
    });
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
<<<<<<< Updated upstream
      // ✅ login — AuthService now saves email to localStorage
      await AuthService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (context.mounted) {
        // ✅ tell DeadlineProvider to fetch from MongoDB now
        await context.read<DeadlineProvider>().loadFromServer();

        // ✅ go to home
        Navigator.pushReplacementNamed(context, '/home');
      }
=======
      await AuthService.login(
        email: emailController.text,
        password: passwordController.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LastBenchHome(),
        ),
      );
>>>>>>> Stashed changes
    } catch (e) {
      setState(() {
        error = "Invalid email or password";
      });
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
<<<<<<< Updated upstream
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text(
                    "New to Last Bench? Create an account",
                    style: TextStyle(color: teal),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Column(
                    children: const [
                      Text(
                        "Welcome to Last Bench",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Sign in to continue your study journey",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
=======
                const SizedBox(height: 30),

                // 🔙 Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    label: const Text("Back"),
                    style: TextButton.styleFrom(
                      foregroundColor: navy,
                    ),
>>>>>>> Stashed changes
                  ),
                ),

                const SizedBox(height: 30),

<<<<<<< Updated upstream
=======
                // 🔹 Heading
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: navy,
                      letterSpacing: -0.6,
                    ),
                    children: [
                      TextSpan(text: "Welcome to "),
                      TextSpan(
                        text: "Last Bench",
                        style: TextStyle(
                          color: teal,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Sign in to continue your study journey",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: hintGrey,
                  ),
                ),

                const SizedBox(height: 36),

                // 🔹 Login Card
>>>>>>> Stashed changes
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderGrey),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  error!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                            const Text(
                              "Email Address",
                              style: TextStyle(
<<<<<<< Updated upstream
                                  fontWeight: FontWeight.bold, color: navy),
=======
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: navy,
                              ),
>>>>>>> Stashed changes
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
<<<<<<< Updated upstream
                                prefixIcon:
                                    const Icon(Icons.mail, color: navy),
=======
>>>>>>> Stashed changes
                                hintText: "yourname@example.com",
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  color: hintGrey,
                                ),
                                prefixIcon: const Icon(
                                  Icons.mail_outline,
                                  color: hintGrey,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: fieldBg,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: borderGrey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: borderGrey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: teal),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return "Email is required";
<<<<<<< Updated upstream
                                if (!value.contains("@"))
=======
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value)) {
>>>>>>> Stashed changes
                                  return "Enter a valid email";
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              "Password",
                              style: TextStyle(
<<<<<<< Updated upstream
                                  fontWeight: FontWeight.bold, color: navy),
=======
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: navy,
                              ),
>>>>>>> Stashed changes
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: passwordController,
                              obscureText: !showPassword,
                              decoration: InputDecoration(
<<<<<<< Updated upstream
                                prefixIcon:
                                    const Icon(Icons.lock, color: navy),
=======
                                hintText: "Enter your password",
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  color: hintGrey,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: hintGrey,
                                  size: 20,
                                ),
>>>>>>> Stashed changes
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: hintGrey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => showPassword = !showPassword),
                                ),
                                filled: true,
                                fillColor: fieldBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: borderGrey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: borderGrey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: teal),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6)
                                  return "Password must be at least 6 characters";
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

<<<<<<< Updated upstream
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: rememberMe,
                                      activeColor: teal,
                                      onChanged: (value) => setState(
                                          () => rememberMe = value ?? false),
                                    ),
                                    const Text("Remember me"),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ForgotPasswordFlow(
                                        onBack: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ),
                                  child: const Text("Forgot password?",
                                      style: TextStyle(color: teal)),
                                ),
                              ],
                            ),
=======
                            
>>>>>>> Stashed changes

                            const SizedBox(height: 22),

<<<<<<< Updated upstream
=======
                            // Sign In Button
>>>>>>> Stashed changes
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: teal,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
<<<<<<< Updated upstream
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isLoading ? null : submitLogin,
                                child: Text(
                                  isLoading ? "Signing in..." : "Sign In",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
=======
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
>>>>>>> Stashed changes
                                ),
                                onPressed:
                                    isLoading ? null : submitLogin,
                                child: isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Sign In",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
<<<<<<< Updated upstream

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: Colors.grey.shade300)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Text("Or continue with",
                                      style:
                                          TextStyle(color: Colors.black54)),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Colors.grey.shade300)),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.g_mobiledata,
                                        color: navy),
                                    label: const Text("Google"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.code, color: navy),
                                    label: const Text("GitHub"),
                                  ),
                                ),
                              ],
                            ),
=======
>>>>>>> Stashed changes
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

<<<<<<< Updated upstream
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text(
                      "New to Last Bench? Create an account",
                      style: TextStyle(color: teal),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    "\"Back benchers welcome. Top ranks guaranteed.\"",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.black45),
=======
                // Signup
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text(
                    "New to Last Bench? Create an account",
                    style: TextStyle(
                      fontSize: 14,
                      color: teal,
                    ),
>>>>>>> Stashed changes
                  ),
                ),

                const SizedBox(height: 12),

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
}