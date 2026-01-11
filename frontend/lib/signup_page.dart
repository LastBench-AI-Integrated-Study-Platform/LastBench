import 'package:flutter/material.dart';
import '../services/auth_service.dart';


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;
  String? selectedExam;

  // Brand colors
  static const Color navy = Color(0xFF033F63);
  static const Color teal = Color(0xFF379392);

  final List<String> examCategories = [
    "JEE Main/Advanced",
    "NEET",
    "UPSC CSE",
    "SSC CGL/CHSL",
    "GATE",
    "CAT",
    "Bank PO/Clerk",
    "Railway Exams",
    "State PSC",
    "NDA",
    "Other",
  ];

 void submitSignup() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => isLoading = true);

  try {
    final msg = await AuthService.signup(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      exam: selectedExam!,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [

                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: navy),
                    label: const Text(
                      "Back",
                      style: TextStyle(
                          color: navy, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Header
                const Text(
                  "Join Last Bench",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Start your journey from the last bench to the top rank",
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Signup Card (Width constrained)
                Center(
                  child: ConstrainedBox(
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
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Full Name
                            const Text("Full Name",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: navy)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: nameController,
                              decoration: _inputDecoration(
                                  Icons.person, "Enter your full name"),
                              validator: (v) =>
                                  v == null || v.length < 2
                                      ? "Name must be at least 2 characters"
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            // Email
                            const Text("Email Address",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: navy)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration(
                                  Icons.mail, "yourname@example.com"),
                              validator: (v) =>
                                  v != null && v.contains("@")
                                      ? null
                                      : "Enter a valid email",
                            ),

                            const SizedBox(height: 16),

                            // Password
                            const Text("Password",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: navy)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: passwordController,
                              obscureText: !showPassword,
                              decoration: _passwordDecoration(
                                "Create a strong password",
                                showPassword,
                                () => setState(
                                    () => showPassword = !showPassword),
                              ),
                              validator: (v) =>
                                  v != null && v.length >= 8
                                      ? null
                                      : "Password must be at least 8 characters",
                            ),

                            const SizedBox(height: 16),

                            // Confirm Password
                            const Text("Confirm Password",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: navy)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: confirmPasswordController,
                              obscureText: !showConfirmPassword,
                              decoration: _passwordDecoration(
                                "Re-enter your password",
                                showConfirmPassword,
                                () => setState(() =>
                                    showConfirmPassword =
                                        !showConfirmPassword),
                              ),
                              validator: (v) =>
                                  v == passwordController.text
                                      ? null
                                      : "Passwords do not match",
                            ),

                            const SizedBox(height: 16),

                            // Exam Dropdown
                            const Text("Target Exam",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: navy)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedExam,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              hint: const Text("Select your target exam"),
                              items: examCategories
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedExam = v),
                              validator: (v) =>
                                  v == null ? "Please select an exam" : null,
                            ),

                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    isLoading ? null : submitSignup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: teal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isLoading
                                      ? "Creating Account..."
                                      : "Create Account",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Footer
                const Text(
                  "\"Your rank doesn't define your potential. Join us.\"",
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.black45),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------ UI Helpers ------------------

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: navy),
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration _passwordDecoration(
      String hint, bool visible, VoidCallback toggle) {
    return InputDecoration(
      prefixIcon: const Icon(Icons.lock, color: navy),
      suffixIcon: IconButton(
        icon: Icon(
          visible ? Icons.visibility_off : Icons.visibility,
          color: navy,
        ),
        onPressed: toggle,
      ),
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
