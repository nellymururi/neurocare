import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

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

  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("Please fill in all fields", Colors.red.shade400);
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _showMessage("Login successful!", Colors.green);
      // Navigate to your home page or desired route
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (e is FirebaseAuthException) {
        // Handle specific FirebaseAuth exceptions with tailored messages
        switch (e.code) {
          case 'user-not-found':
            _showMessage(
                "No account found with this email. Please check or sign up.",
                Colors.red.shade400);
            break;
          case 'wrong-password':
            _showMessage(
                "Incorrect password. Please try again.", Colors.red.shade400);
            break;
          case 'invalid-email':
            _showMessage(
                "The email address is not valid. Please enter a valid email.",
                Colors.red.shade400);
            break;
          case 'user-disabled':
            _showMessage(
                "This user account has been disabled. Please contact support.",
                Colors.red.shade400);
            break;
          case 'operation-not-allowed':
            _showMessage(
                "Email/password accounts are not enabled. Please contact support.",
                Colors.red.shade400);
            break;
          default:
            _showMessage("Login failed: ${e.message}", Colors.red.shade400);
            break;
        }
      } else {
        _showMessage("An unexpected error occurred. Please try again.",
            Colors.red.shade400);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
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
              onPressed: _loginUser,
              child: const Text("Login"),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      "Sign Up",
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
