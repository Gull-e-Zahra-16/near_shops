import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  final String role;
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String _passwordStrength = "";

  // ✅ Password strength check (improved with detailed suggestions)
  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() => _passwordStrength = "");
      return;
    }

    String message;
    if (password.length < 6) {
      message = "Too short – at least 6 characters required.";
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      message = "Add at least one UPPERCASE letter.";
    } else if (!RegExp(r'[a-z]').hasMatch(password)) {
      message = "Add at least one lowercase letter.";
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      message = "Add at least one number.";
    } else if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      message = "Add at least one special character (! @ # \$ & * ~).";
    } else {
      message = "Strong Password 💪";
    }

    setState(() => _passwordStrength = message);
  }

  Future<void> _signup() async {
    // 🚫 Stop signup if role is "Admin"
    if (widget.role.toLowerCase() == "admin") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "You cannot create a new Admin account. Admin access is restricted."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordStrength != "Strong Password 💪") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please use a stronger password!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': widget.role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${widget.role} account created successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup failed"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color blue = Color(0xFF1565C0);
    const Color orange = Color(0xFFF4511E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "${widget.role} Signup",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [blue, orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 Top Icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [orange, blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.person_add_alt_1, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 25),

            const Text(
              "Create Your Account",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Sign up to continue using NearShop",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 30),

            // 🔹 Card with Input Fields
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Icons.person, color: blue),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email, color: blue),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      onChanged: _checkPasswordStrength,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock, color: blue),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                    ),
                    if (_passwordStrength.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _passwordStrength,
                          style: TextStyle(
                            color: _passwordStrength.contains("Strong")
                                ? Colors.green
                                : Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 35),

            // 🔹 Sign Up Button
            ElevatedButton(
              onPressed: _isLoading ? null : _signup,
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),

            const SizedBox(height: 20),

            // 🔹 Back to Login
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: blue),
              label: const Text(
                "Back to Login",
                style: TextStyle(color: blue, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}