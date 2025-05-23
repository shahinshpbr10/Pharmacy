import 'package:flutter/material.dart';

enum AuthMode { signIn, signUp }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AuthMode _authMode = AuthMode.signIn;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  void _switchMode() {
    setState(() {
      _authMode = _authMode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
    });
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (_authMode == AuthMode.signIn) {
      print("🔐 Signing in with $email / $password");
    } else {
      print("🆕 Signing up $name with $email / $password");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _authMode == AuthMode.signIn;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/ZAPPQ WORDMARK-01 2.png', height: 80),
                  const SizedBox(height: 20),
                  Text(
                    isSignIn ? "Welcome Back" : "Create Your Account",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  if (!isSignIn)
                    TextField(
                      controller: _nameController,
                      decoration: _inputDecoration("Full Name", Icons.person),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: _inputDecoration("Email", Icons.email),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: _inputDecoration("Password", Icons.lock),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isSignIn ? "Sign In" : "Sign Up"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _switchMode,
                    child: Text(
                      isSignIn
                          ? "Don't have an account? Sign Up"
                          : "Already have an account? Sign In",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
