import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Developer/Guest Bypass: If fields are empty, enter the app anyway
    if (email.isEmpty && password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Entering Preview Mode...'),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter your email and password.'),
          backgroundColor: AppColors.surfaceRaised,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );
      if (response.user != null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        String message = e.toString().replaceAll('Exception: ', '');
        
        if (errorStr.contains('429') || errorStr.contains('too many requests')) {
          message = 'Too many attempts. Please wait a minute or use "Enter as Guest".';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.surfaceRaised,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
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
              const SizedBox(height: 64),

              // Header
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'PA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Welcome back.',
                style: AppTextStyles.displayMedium,
              ),

              const SizedBox(height: 8),

              const Text(
                'No excuses. Log in and get to work.',
                style: AppTextStyles.body,
              ),

              const SizedBox(height: 48),

              // Email field
              _FieldLabel(text: 'EMAIL'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                ),
              ),

              const SizedBox(height: 20),

              // Password field
              _FieldLabel(text: 'PASSWORD'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Log in'),
                ),
              ),

              const SizedBox(height: 16),

              // Explicit Guest Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Enter as Guest',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Divider
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or', style: AppTextStyles.bodySmall),
                ),
                Expanded(child: Divider()),
              ]),

              const SizedBox(height: 48),

              // Sign up nudge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: AppTextStyles.body,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/signup'),
                    child: const Text(
                      'Sign up',
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

// Small reusable label widget
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}