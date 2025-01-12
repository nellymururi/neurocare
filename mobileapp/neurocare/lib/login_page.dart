import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forgot_password_screen.dart';
import 'auth_service.dart';
import 'fingerprint_auth_service.dart';
import 'admin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();
  final FingerprintAuthService _fingerprintAuthService =
      FingerprintAuthService();
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
      // Authenticate user using email and password
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = _auth.currentUser;
      if (user != null) {
        // Fetch document by email instead of UID
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (querySnapshot.docs.isEmpty) {
          print("No Firestore document found for email: ${user.email}");
          _showMessage(
              "User data not found in Firestore.", Colors.red.shade400);
          return;
        }

        final userDoc = querySnapshot.docs.first;
        final role = userDoc.data()['role'];
        print("Role retrieved from Firestore: $role");
        // Navigate based on role

        if (role == 'admin') {
          _showMessage("Admin login successful!", Colors.green);
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'user') {
          _showMessage("User login successful!", Colors.green);
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _showMessage(
            "Unknown role. Please contact support.",
            Colors.red.shade400,
          );
          print("Unexpected role: $role for UID: ${user.uid}");
        }
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        // Handle specific FirebaseAuth exceptions
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
        // Handle unexpected errors
        _showMessage("An unexpected error occurred. Please try again.",
            Colors.red.shade400);
        print("Unexpected error: $e");
      }
    }
  }

//for google sign in
  Future<void> _handleGoogleSignIn() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      _showMessage("Google sign-up successful!", Colors.green);
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showMessage(
          "Google sign-in failed. Please try again.", Colors.red.shade400);
    }
  }

  // For fingerprint login
  Future<void> _loginWithFingerprint() async {
    bool canAuthenticate = await _fingerprintAuthService.isBiometricAvailable();
    if (canAuthenticate) {
      bool authenticated = await _fingerprintAuthService.authenticate();
      if (authenticated) {
        _showMessage("Fingerprint authentication successful!", Colors.green);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMessage(
            "Authentication failed. Please try again.", Colors.red.shade400);
      }
    } else {
      _showMessage(
          "Biometric authentication is not available.", Colors.red.shade400);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
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
                child: Column(
                  children: [
                    Row(
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
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _handleGoogleSignIn,
                icon: Image.asset(
                  'assets/google_icon.png',
                  height: 24,
                ),
                label: const Text("Sign in with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loginWithFingerprint,
                icon: Image.asset(
                  'assets/fingerprint_icon.png',
                  height: 24,
                ),
                label: const Text("Login with Fingerprint"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
