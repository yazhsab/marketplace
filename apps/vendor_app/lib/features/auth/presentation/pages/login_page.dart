import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isPhoneLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    if (_isPhoneLogin) {
      final phone = '+91${_phoneController.text.trim()}';
      ref.read(authProvider.notifier).sendOtp(phone: phone);
    } else {
      ref.read(authProvider.notifier).loginWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthOtpSent) {
        context.push('/otp', extra: {
          'phone': next.phone,
          'verificationId': next.verificationId,
        });
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    });

    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Gradient header -- 30% of screen
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Storefront icon in semi-transparent circle
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Sign in to manage your business',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // White card body overlapping gradient by 20px
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.35 - 20,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingXl,
                  AppTheme.spacing2xl,
                  AppTheme.spacingXl,
                  AppTheme.spacingXl,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Segmented pill toggle for Phone/Email
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Row(
                          children: [
                            _buildSegment('Phone', _isPhoneLogin, () {
                              setState(() => _isPhoneLogin = true);
                            }),
                            _buildSegment('Email', !_isPhoneLogin, () {
                              setState(() => _isPhoneLogin = false);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),

                      // Phone Login Fields
                      if (_isPhoneLogin) ...[
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter your 10-digit phone number',
                            prefixText: '+91 ',
                            prefixIcon: Icon(Icons.phone_outlined),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (!value.isValidPhone) {
                              return 'Please enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),
                      ],

                      // Email Login Fields
                      if (!_isPhoneLogin) ...[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.isValidEmail) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingBase),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppTheme.textTertiary,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
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
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingXl),

                      // Gradient Login Button (52px)
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: isLoading
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primary.withValues(alpha: 0.6),
                                    const Color(0xFF60A5FA)
                                        .withValues(alpha: 0.6),
                                  ],
                                )
                              : AppTheme.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoading ? null : _handleLogin,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isPhoneLogin ? 'Send OTP' : 'Login',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing2xl),

                      // "Don't have an account?" footer link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: Text(
                              'Register',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            boxShadow: isSelected ? AppTheme.shadowSm : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
