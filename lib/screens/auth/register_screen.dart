import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../home/home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends ConsumerState<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Validation
    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please fill all fields.');
      return;
    }

    if (!email.contains('@')) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (phone.length < 10) {
      _showMessage('Please enter a valid mobile number.');
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Password must be at least 6 characters.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final initials = _getInitials(name);

    final user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phoneNumber: phone,
      password: password,
      initials: initials,
      online: true,
    );

    final error = await ref
        .read(authProvider.notifier)
        .register(user: user);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (error != null) {
      _showMessage(error);
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(),
      ),
      (_) => false,
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(size: 58),

              const SizedBox(height: 25),

              const Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Create an account to start connecting.',
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Full name',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: nameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: emailController,
                keyboardType:
                    TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Mobile number',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  hintText: 'Enter 10-digit mobile number',
                  counterText: '',
                  prefixText: '+91 ',
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Password',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Minimum 6 characters',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Confirm password',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Re-enter your password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword =
                            !obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              PrimaryButton(
                label: isLoading
                    ? 'Creating Account...'
                    : 'Create Account',
                onPressed:
                    isLoading ? null : register,
              ),

              const SizedBox(height: 22),

              Center(
                child: Wrap(
                  children: [
                    const Text(
                      'Already have an account? ',
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}