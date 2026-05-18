import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _currentStep = 0; // 0 = identity, 1 = credentials

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Guest Bypass: If name and username are empty, skip to credentials
      if (_nameController.text.trim().isEmpty &&
          _usernameController.text.trim().isEmpty) {
        setState(() => _currentStep = 1);
        return;
      }

      if (_nameController.text.trim().isEmpty ||
          _usernameController.text.trim().isEmpty) {
        _showError('Fill in your name and username first.');
        return;
      }
      setState(() => _currentStep = 1);
    } else {
      _handleSignup();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: Colors.black)),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Guest Bypass: If credentials are empty, just enter the app
    if (email.isEmpty && password.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showError('Email and password are required.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
      );
      if (response.user != null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Back button
              GestureDetector(
                onTap: () => _currentStep == 1
                    ? setState(() => _currentStep = 0)
                    : Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back,
                    color: AppColors.textSecondary, size: 20),
              ),

              const SizedBox(height: 40),

              // Step indicator
              _StepIndicator(currentStep: _currentStep),

              const SizedBox(height: 32),

              // Heading
              Text(
                _currentStep == 0 ? 'Who are you?' : 'Secure your account.',
                style: AppTextStyles.displayMedium,
              ),

              const SizedBox(height: 8),

              Text(
                _currentStep == 0
                    ? 'Your circle will hold you to this name.'
                    : 'Make it something you\'ll remember.',
                style: AppTextStyles.body,
              ),

              const SizedBox(height: 40),

              // Step 0 — Identity
              if (_currentStep == 0) ...[
                _FieldLabel(text: 'FULL NAME'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Your full name'),
                ),

                const SizedBox(height: 20),

                _FieldLabel(text: 'USERNAME'),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. jibraan_x',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: Text('@',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14)),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'This is how your circle sees you. Choose wisely.',
                  style: AppTextStyles.bodySmall,
                ),
              ],

              // Step 1 — Credentials
              if (_currentStep == 1) ...[
                _FieldLabel(text: 'EMAIL'),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration:
                      const InputDecoration(hintText: 'you@example.com'),
                ),

                const SizedBox(height: 20),

                _FieldLabel(text: 'PASSWORD'),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Min. 8 characters',
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Password strength hint
                _PasswordHint(password: _passwordController.text),
              ],

              const SizedBox(height: 40),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : Text(_currentStep == 0 ? 'Continue' : 'Create account'),
                ),
              ),

              const SizedBox(height: 32),

              // Login nudge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already in? ', style: AppTextStyles.body),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/login'),
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (index) {
        final isActive = index == currentStep;
        final isDone = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 0 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: isDone || isActive
                  ? AppColors.accent
                  : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _PasswordHint extends StatelessWidget {
  final String password;
  const _PasswordHint({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = password.length >= 12
        ? 'Strong'
        : password.length >= 8
            ? 'Fair'
            : password.isEmpty
                ? ''
                : 'Too short';

    final color = password.length >= 12
        ? AppColors.success
        : password.length >= 8
            ? AppColors.warning
            : AppColors.danger;

    if (strength.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(strength,
            style: TextStyle(fontSize: 11, color: color,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: AppColors.textMuted, letterSpacing: 1.2));
  }
}