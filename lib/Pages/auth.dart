import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../enum/enums.dart';


class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AuthMode _authMode = AuthMode.signIn;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  void _switchMode() {
    setState(() {
      _authMode =
      _authMode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;

      if (_authMode == AuthMode.signIn) {
        final query = await firestore
            .collection('pharmacy')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isEmpty ||
            query.docs.first['approvalStatus'] != 'approved') {
          _showSnackBar('Access Denied. Approval Pending or Not Found.', true);
          setState(() => _isLoading = false);
          return;
        }

        await auth.signInWithEmailAndPassword(
            email: email, password: password);
        _showSnackBar('Signed in successfully!');
      } else {
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await firestore
            .collection('pharmacy')
            .doc(userCredential.user!.uid)
            .set({
          'name': name,
          'email': email,
          'approvalStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSnackBar('Account created. Awaiting admin approval.');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, [bool isError = false]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _authMode == AuthMode.signIn;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/ZAPPQ WORDMARK-01 2.png', height: 80),
                      const SizedBox(height: 20),
                      Text(
                        isSignIn ? "Welcome Back" : "Create Your Account",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!isSignIn)
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration("Full Name", Icons.person),
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration("Email", Icons.email),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                        value == null || !value.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: _inputDecoration("Password", Icons.lock),
                        obscureText: true,
                        validator: (value) =>
                        value != null && value.length < 6
                            ? 'Minimum 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                          )
                              : Text(isSignIn ? "Sign In" : "Sign Up"),
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
        ),
      ),
    );
  }
}
