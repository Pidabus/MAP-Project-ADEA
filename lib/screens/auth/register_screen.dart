import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/loading_overlay.dart';

/// Register Screen — Create new account with name, email, and password
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(RegisterEvent(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: const Color(0xFFA32D2D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF2F3F7);
        final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
        final subtextColor = isDark ? const Color(0xFFc2c6d2) : const Color(0xFF6B7280);
        final iconBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
        final dividerColor = isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade300;

        return Scaffold(
          backgroundColor: bgColor,
          body: LoadingOverlay(
            isLoading: state is AuthLoading,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: iconBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Create\nAccount ✨', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor, height: 1.2)),
                    const SizedBox(height: 8),
                    Text('Start your journey to a more organized life', style: TextStyle(fontSize: 14, color: subtextColor)),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(children: [
                        CustomTextField(controller: _nameCtrl, label: 'Full Name', hint: 'Enter your full name', prefixIcon: Icons.person_outline_rounded, validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter your name';
                          if (v.length < 2) return 'Name must be at least 2 characters';
                          return null;
                        }),
                        const SizedBox(height: 16),
                        CustomTextField(controller: _emailCtrl, label: 'Email Address', hint: 'Enter your email', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter your email';
                          if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v)) return 'Please enter a valid email';
                          return null;
                        }),
                        const SizedBox(height: 16),
                        CustomTextField(controller: _passCtrl, label: 'Password', hint: 'Create a password', prefixIcon: Icons.lock_outline_rounded, obscureText: !_showPass,
                          suffixIcon: IconButton(icon: Icon(_showPass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF9CA3AF), size: 22), onPressed: () => setState(() => _showPass = !_showPass)),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter a password';
                            if (v.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          }),
                        const SizedBox(height: 16),
                        CustomTextField(controller: _confirmCtrl, label: 'Confirm Password', hint: 'Re-enter your password', prefixIcon: Icons.lock_outline_rounded, obscureText: !_showConfirm,
                          suffixIcon: IconButton(icon: Icon(_showConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF9CA3AF), size: 22), onPressed: () => setState(() => _showConfirm = !_showConfirm)),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please confirm your password';
                            if (v != _passCtrl.text) return 'Passwords do not match';
                            return null;
                          }),
                        const SizedBox(height: 24),
                        PrimaryButton(text: 'Create Account', onPressed: _register, isLoading: state is AuthLoading),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    Row(children: [
                      Expanded(child: Divider(color: dividerColor, thickness: 1)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Or sign up with', style: TextStyle(color: subtextColor, fontSize: 12))),
                      Expanded(child: Divider(color: dividerColor, thickness: 1)),
                    ]),
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, height: 52, child: OutlinedButton(
                      onPressed: () => context.read<AuthBloc>().add(LoginWithGoogleEvent()),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: dividerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
                        const SizedBox(width: 12),
                        Text('Sign up with Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                      ]),
                    )),
                    const SizedBox(height: 28),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Already have an account? ', style: TextStyle(color: subtextColor, fontSize: 14)),
                      GestureDetector(onTap: () => Navigator.pop(context), child: const Text('Sign In', style: TextStyle(color: Color(0xFF185FA5), fontWeight: FontWeight.w700, fontSize: 14))),
                    ]),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
