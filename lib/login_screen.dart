import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'customer_dashboard.dart';
import 'shopkeeper_dashboard.dart';
import 'admin_dashboard.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  final String mainAdminUID = "sYf4uOsCnBhbZ6khzF4y21Ii0W13";
  final String mainAdminEmail = "nearbuyadmin@gmail.com";

  Future<void> _loginUser() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (widget.role == "Admin" && email != mainAdminEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Access Denied! Only the main Admin can login."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final savedRole = userDoc['role'];

        if (widget.role == "Admin") {
          if (uid == mainAdminUID && savedRole == "Admin") {
            _navigateTo(AdminDashboard());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text("Access Denied! Only the main Admin can access."),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (savedRole == widget.role) {
          if (widget.role == "Customer") {
            _navigateTo(CustomerDashboard());
          } else if (widget.role == "Shopkeeper") {
            _navigateTo(ShopkeeperDashboard());
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Access Denied! This account is registered as $savedRole."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User record not found in Firestore!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Login failed!"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateTo(Widget screen) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Welcome ${widget.role}! Login successful 🎉"),
        backgroundColor: Colors.green,
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => screen),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color orange = const Color(0xFFF4511E);
    final Color blue = const Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Back",
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // 🔹 Header (NearBuy text)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    children: [
                      TextSpan(text: "Near", style: TextStyle(color: blue)),
                      TextSpan(text: "Buy", style: TextStyle(color: orange)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${widget.role} Login",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),

                // 🔹 Login Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () =>
                                setState(() => _obscureText = !_obscureText),
                          ),
                        ),
                      ),
                      if (widget.role != "Admin")
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(color: blue),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // 🔹 Gradient Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [blue, orange],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: _isLoading ? null : _loginUser,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                if (widget.role != "Admin")
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SignupScreen(role: widget.role),
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don’t have an account? ",
                        style:
                            const TextStyle(color: Colors.black87, fontSize: 15),
                        children: [
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              color: orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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