import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpPage> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final AuthService _authService = AuthService();
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  // Function to display custom error messages
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Function to validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Function to validate password format
  bool _isValidPassword(String password) {
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*\W).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _registerUser() async {
    if (!_isValidEmail(_emailController.text.trim())) {
      _showMessage("Please enter a valid email address", Colors.red.shade400);
      return;
    }
    if (!_isValidPassword(_passwordController.text.trim())) {
      _showMessage(
          "Password must be at least 8 characters, including an uppercase letter, number, and special character",
          Colors.red.shade400);
      return;
    }
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("Please fill in all fields", Colors.red.shade400);
      return;
    }
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _showMessage("Registration successful! Please log in.", Colors.green);
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        _showMessage("User already registered", Colors.red.shade400);
      } else {
        _showMessage(
            "Registration failed: ${e.toString()}", Colors.red.shade400);
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        _showMessage("Google sign-up successful!", Colors.green);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMessage(
            "Google sign-up failed. Please try again.", Colors.red.shade400);
      }
    } catch (e) {
      _showMessage(
          "Google sign-up error: ${e.toString()}", Colors.red.shade400);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: const Text("Register"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signUpWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize
                    .min, // Ensures the button size fits the content
                children: [
                  Image.asset(
                    'assets/google_icon.png', // Make sure this file exists in assets
                    height: 24,
                    width: 24, // You can adjust the width if needed
                  ),
                  const SizedBox(
                      width: 10), // Add space between the icon and text
                  const Text(
                    "Sign up with Google",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
