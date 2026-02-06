// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- NEW STATE FOR FIELD-SPECIFIC ERRORS ---
  String? _storeError;
  String? _usernameError;
  String? _passwordError;
  // --------------------------------------------

  void _submitLogin() {
    // 1. Clear previous errors
    setState(() {
      _storeError = null;
      _usernameError = null;
      _passwordError = null;
      _isLoading = true;
    });

    // Quick check for empty fields (Flutter's default validation/focus behavior)
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // --- CAPTURE CREDENTIALS ---
    final storeName = _storeNameController.text.trim().toLowerCase();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // --- HARDCODED AUTHENTICATION LOGIC ---
    const requiredStore = 'store-1';
    const requiredUsername = 'admin';
    const requiredPassword = '123';

    bool loginSuccess = true;

    if (storeName != requiredStore) {
      _storeError = 'Invalid Store Name.';
      loginSuccess = false;
    }
    if (username != requiredUsername) {
      _usernameError = 'Invalid Username.';
      loginSuccess = false;
    }
    if (password != requiredPassword) {
      _passwordError = 'Invalid Password.';
      loginSuccess = false;
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _isLoading = false;
      });

      if (loginSuccess) {
        // SUCCESS: Navigate to Home
        Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {'storeName': storeName.toUpperCase()}
        );
      } else {
        // FAILURE: Errors are now displayed below the fields via setState
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please correct the highlighted errors.')),
        );
      }
    });
  }

  // --- Helper Widget for Input Field with Dynamic Error Display ---
  Widget _buildValidatedField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? errorText,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: labelText,
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
            // Use basic validator to enforce required field, detailed error comes from state
            errorText: errorText,
          ),
          validator: (value) => value == null || value.isEmpty ? '$labelText is required' : null,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(35.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fastfood, size: 60, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 10),
                  Text(
                    'AIoT Food Expiry System',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 25),

                  // Store Name Input
                  _buildValidatedField(
                    controller: _storeNameController,
                    labelText: 'Store Name (e.g., store-1)',
                    icon: Icons.store,
                    errorText: _storeError,
                  ),
                  const SizedBox(height: 18),

                  // Username Input
                  _buildValidatedField(
                    controller: _usernameController,
                    labelText: 'Username',
                    icon: Icons.person,
                    errorText: _usernameError,
                  ),
                  const SizedBox(height: 18),

                  // Password Input
                  _buildValidatedField(
                    controller: _passwordController,
                    labelText: 'Password',
                    icon: Icons.lock,
                    errorText: _passwordError,
                    obscureText: true,
                  ),
                  const SizedBox(height: 40),

                  // Login Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _submitLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 5,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    child: const Text('LOG IN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}