import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/exceptions.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/social_login_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _navigatedToMain = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final cred = await authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Require verified email before proceeding
      final user = cred.user;
      if (mounted) {
        if (user != null && !user.emailVerified) {
          context.go(AppRoutes.verifyEmail);
        } else {
          // Clear any pending SnackBars and navigate
          ScaffoldMessenger.of(context).clearSnackBars();
          _navigatedToMain = true;
          // Let the router handle the redirect based on profile completion
          context.go('/');
        }
      }
    } on AuthException catch (e) {
      // If this email is registered with Google only, offer to link a password
      if (e.message.toLowerCase().contains('google')) {
        await _offerGoogleLinkPasswordFlow(_emailController.text.trim());
        return;
      }
    if (mounted && !_navigatedToMain) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _offerGoogleLinkPasswordFlow(String email) async {
    if (!mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use Google for this email'),
        content: const Text(
          'This email is registered with Google. Sign in with Google to link a password so you can also log in with email/password next time.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue with Google')),
        ],
      ),
    );
    if (proceed != true) return;

    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithGoogle();
      if (!mounted) return;

      // Prompt for new password
      final controller1 = TextEditingController();
      final controller2 = TextEditingController();
      final formKey = GlobalKey<FormState>();
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Create a password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller1,
                  decoration: const InputDecoration(labelText: 'New password'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                TextFormField(
                  controller: controller2,
                  decoration: const InputDecoration(labelText: 'Confirm password'),
                  obscureText: true,
                  validator: (v) {
                    if (v != controller1.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save Password'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        try {
          await auth.linkEmailPassword(email: email, password: controller1.text);
          if (!mounted) return;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password linked. You can now sign in with email/password.')),
          );
          _navigatedToMain = true;
          // Let the router handle the redirect based on profile completion
          context.go('/');
        } on AuthException catch (e) {
          if (mounted && !_navigatedToMain) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorColor),
            );
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Email verification modal removed; we now use a dedicated page.

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        _navigatedToMain = true;
        // Let the router handle the redirect based on profile completion
        context.go('/');
      }
    } on AuthException catch (e) {
      if (mounted && !_navigatedToMain) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Facebook Sign-In is disabled in this build; method removed to avoid unused warnings.

  Future<void> _signInWithApple() async {
    // Apple Sign-In temporarily disabled
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple Sign-In is temporarily unavailable'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
    
    /* Temporarily disabled
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithApple();
      
      if (mounted) {
        context.go(AppRoutes.mainNavigation);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Header
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 40,
                          color: Colors.white,
                        ),
                      ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Welcome Back!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().slideY(
                        begin: 0.3,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      ).fadeIn(),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Sign in to continue your journey',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ).animate(delay: 200.ms).slideY(
                        begin: 0.3,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      ).fadeIn(),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ).animate(delay: 400.ms).slideX(
                    begin: 0.3,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ).fadeIn(),
                  
                  const SizedBox(height: 20),
                  
                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: 'Enter your password',
                    obscureText: !_isPasswordVisible,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ).animate(delay: 600.ms).slideX(
                    begin: 0.3,
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ).fadeIn(),
                  
                  const SizedBox(height: 12),
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.forgotPassword),
                      child: const Text('Forgot Password?'),
                    ),
                  ).animate(delay: 800.ms).fadeIn(),
                  
                  const SizedBox(height: 32),
                  
                  // Sign In Button
                  ElevatedButton(
                    onPressed: _signInWithEmail,
                    child: const Text('Sign In'),
                  ).animate(delay: 1000.ms).scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ).animate(delay: 1200.ms).fadeIn(),
                  
                  const SizedBox(height: 32),
                  
                  // Social Login Buttons
                  Column(
                    children: [
                      SocialLoginButton(
                        onPressed: _signInWithGoogle,
                        icon: Icons.g_mobiledata,
                        label: 'Continue with Google',
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        borderColor: Colors.grey.shade300,
                      ).animate(delay: 1400.ms).slideX(
                        begin: -0.3,
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      ).fadeIn(),
                      
                      const SizedBox(height: 12),
                      
                      // Facebook disabled in this build
                      
                      const SizedBox(height: 12),
                      
                      if (Theme.of(context).platform == TargetPlatform.iOS)
                        SocialLoginButton(
                          onPressed: _signInWithApple,
                          icon: Icons.apple,
                          label: 'Continue with Apple',
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                        ).animate(delay: 1800.ms).slideX(
                          begin: -0.3,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        ).fadeIn(),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.signup),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ).animate(delay: 2000.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
