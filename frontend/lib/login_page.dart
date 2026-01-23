import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'last_bench_home.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool showPassword = false;
  bool rememberMe = false;
  bool isLoading = false;
  String? error;

  // Brand colors
  static const Color navy = Color(0xFF033F63);
  static const Color teal = Color(0xFF379392);

  void submitLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    isLoading = true;
    error = null;
  });

  try {
    final res = await AuthService.login(
      email: emailController.text,
      password: passwordController.text,
    );

    // 👇 login success
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const LastBenchHome(),
  ),
);

  } catch (e) {
    setState(() => error = e.toString());
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Back button
                TextButton(
  onPressed: () {
    Navigator.pushNamed(context, '/signup');
  },
  child: const Text(
    "New to Last Bench? Create an account",
    style: TextStyle(color: teal),
  ),
),


                const SizedBox(height: 20),

                // Header
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
                  ),
                ),

                const SizedBox(height: 30),

                // 🔹 LOGIN CARD (WIDTH REDUCED)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420, // 👈 adjust (380–450)
                    ),
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

                            if (error != null)
                              Container(
                                margin:
                                    const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  error!,
                                  style: const TextStyle(
                                      color: Colors.red),
                                ),
                              ),

                            // Email
                            const Text(
                              "Email Address",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: navy),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: emailController,
                              keyboardType:
                                  TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.mail,
                                    color: navy),
                                hintText:
                                    "yourname@example.com",
                                filled: true,
                                fillColor:
                                    Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return "Email is required";
                                }
                                if (!value.contains("@")) {
                                  return "Enter a valid email";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Password
                            const Text(
                              "Password",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: navy),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: passwordController,
                              obscureText: !showPassword,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock,
                                    color: navy),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: navy,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      showPassword =
                                          !showPassword;
                                    });
                                  },
                                ),
                                hintText:
                                    "Enter your password",
                                filled: true,
                                fillColor:
                                    Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.length < 6) {
                                  return "Password must be at least 6 characters";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            // Remember + Forgot
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: rememberMe,
                                      activeColor: teal,
                                      onChanged: (value) {
                                        setState(() {
                                          rememberMe =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                    const Text("Remember me"),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    "Forgot password?",
                                    style:
                                        TextStyle(color: teal),
                                  ),
                                )
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: teal,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                  ),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : submitLogin,
                                child: Text(
                                  isLoading
                                      ? "Signing in..."
                                      : "Sign In",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: Colors
                                            .grey.shade300)),
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(
                                          horizontal: 8),
                                  child: Text(
                                    "Or continue with",
                                    style: TextStyle(
                                        color:
                                            Colors.black54),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Colors
                                            .grey.shade300)),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Social buttons
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                        Icons.g_mobiledata,
                                        color: navy),
                                    label:
                                        const Text("Google"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child:
                                      OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.code,
                                        color: navy),
                                    label:
                                        const Text("GitHub"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Signup
                Center(
                  child: TextButton(
                    onPressed: () {},
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
                        fontStyle: FontStyle.italic,
                        color: Colors.black45),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
