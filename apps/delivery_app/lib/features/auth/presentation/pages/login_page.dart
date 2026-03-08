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

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
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
    final screenHeight = MediaQuery.of(context).size.height;

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // -- Gradient Header (30% screen) --
            Container(
              width: double.infinity,
              height: screenHeight * 0.30,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delivery_dining,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    Text(
                      'Welcome back',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Delivery Partner Login',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -- White Card Body overlapping gradient --
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                decoration: const BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusXl),
                    topRight: Radius.circular(AppTheme.radiusXl),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingSm),

                      // -- Phone / Email Segmented Toggle --
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXs),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            _buildSegmentTab(
                              theme,
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              isSelected: _isPhoneLogin,
                              onTap: () =>
                                  setState(() => _isPhoneLogin = true),
                            ),
                            _buildSegmentTab(
                              theme,
                              icon: Icons.email_outlined,
                              label: 'Email',
                              isSelected: !_isPhoneLogin,
                              onTap: () =>
                                  setState(() => _isPhoneLogin = false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),

                      // -- Phone Input --
                      if (_isPhoneLogin) ...[
                        Text(
                          'Phone Number',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: InputDecoration(
                            hintText: 'Enter your 10-digit phone number',
                            prefixText: '+91 ',
                            prefixIcon: Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: const Icon(Icons.phone_outlined,
                                  color: AppTheme.textSecondary, size: 20),
                            ),
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

                      // -- Email / Password Inputs --
                      if (!_isPhoneLogin) ...[
                        Text(
                          'Email',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your email address',
                            prefixIcon: Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: const Icon(Icons.email_outlined,
                                  color: AppTheme.textSecondary, size: 20),
                            ),
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
                        Text(
                          'Password',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: const Icon(Icons.lock_outlined,
                                  color: AppTheme.textSecondary, size: 20),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppTheme.textTertiary,
                                size: 20,
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
                      const SizedBox(height: AppTheme.spacing2xl),

                      // -- Gradient Login Button --
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient:
                              isLoading ? null : AppTheme.primaryGradient,
                          color: isLoading
                              ? AppTheme.primary.withValues(alpha: 0.5)
                              : null,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: isLoading
                              ? null
                              : [
                                  BoxShadow(
                                    offset: const Offset(0, 4),
                                    blurRadius: 12,
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.3),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                            onTap: isLoading ? null : _handleLogin,
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
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
                      const SizedBox(height: AppTheme.spacingXl),

                      // -- Footer Link --
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New delivery partner? ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/onboarding'),
                            child: Text(
                              'Register here',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingBase),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: isSelected ? AppTheme.shadowSm : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
