// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/lnu_button.dart';
import '../../shared/widgets/lnu_text_field.dart';
import '../../core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await SupabaseService.login(_emailCtrl.text.trim().toLowerCase(), _passwordCtrl.text);
      if (!mounted) return;
      if (res.user != null) {
        final meta = res.user!.userMetadata;
        final role = meta?['role'] ?? 'student';
        if (role == 'admin') {
          context.go('/superadmin');
        } else if (role == 'staff') {
          context.go('/admin');
        } else {
          context.go('/student');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: LNUColors.darkBlue),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: LNUColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 0 : 24,
              vertical: 40,
            ),
            child: Container(
              width: isDesktop ? 460 : double.infinity,
              padding: isDesktop
                  ? const EdgeInsets.symmetric(horizontal: 48, vertical: 48)
                  : EdgeInsets.zero,
              decoration: isDesktop
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildForm(),
                  const SizedBox(height: 24),
                  LNUButton(label: 'Sign In', onPressed: _login, isLoading: _loading),
                  const SizedBox(height: 16),
                  _buildLinks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // LNU Logo
        Image.asset(
          'assets/lnu_logo.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        const Text(
          'LNU Registrar',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: LNUColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          'Queue & Request Management System',
          style: const TextStyle(fontSize: 14, color: LNUColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          LNUTextField(
            label: 'Email Address',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: LNUValidators.email,
          ),
          const SizedBox(height: 16),
          LNUTextField(
            label: 'Password',
            controller: _passwordCtrl,
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outline),
            validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLinks() {
    return Column(
      children: [
        TextButton(
          onPressed: () => context.push('/forgot-password'),
          child: const Text('Forgot Password?', style: TextStyle(color: LNUColors.primary)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account? ", style: TextStyle(color: LNUColors.textMuted)),
            GestureDetector(
              onTap: () => context.push('/register'),
              child: const Text('Sign Up', style: TextStyle(color: LNUColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
