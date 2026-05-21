// lib/features/auth/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/lnu_button.dart';
import '../../shared/widgets/lnu_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _done = false;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordCtrl.text),
      );
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: LNUColors.darkBlue,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LNUColors.background,
      appBar: AppBar(
        title: const Text('Set New Password'),
        backgroundColor: LNUColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width >= 768 ? 0 : 24,
              vertical: 40,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width >= 768 ? 460 : double.infinity,
              padding: MediaQuery.of(context).size.width >= 768
                  ? const EdgeInsets.symmetric(horizontal: 48, vertical: 48)
                  : EdgeInsets.zero,
              decoration: MediaQuery.of(context).size.width >= 768
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
              child: _done ? _buildSuccess() : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.lock_reset, size: 64, color: LNUColors.primary),
          const SizedBox(height: 20),
          const Text(
            'Create New Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a strong password for your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: LNUColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 32),
          LNUTextField(
            label: 'New Password',
            controller: _passwordCtrl,
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outline),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          LNUTextField(
            label: 'Confirm New Password',
            controller: _confirmCtrl,
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outline),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          LNUButton(
            label: 'Update Password',
            onPressed: _updatePassword,
            isLoading: _loading,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle_outline, size: 80, color: LNUColors.blue),
        const SizedBox(height: 24),
        const Text(
          'Password Updated!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your password has been successfully updated.\nYou can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: LNUColors.textMuted),
        ),
        const SizedBox(height: 32),
        LNUButton(
          label: 'Sign In',
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
    );
  }
}
