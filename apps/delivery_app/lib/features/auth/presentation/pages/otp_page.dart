import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String phone;
  final String verificationId;

  const OtpPage({
    super.key,
    required this.phone,
    required this.verificationId,
  });

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;
    ref.read(authProvider.notifier).verifyOtp(
          phone: widget.phone,
          otp: otp,
          verificationId: widget.verificationId,
        );
  }

  void _resendOtp() {
    if (!_canResend) return;
    ref.read(authProvider.notifier).sendOtp(phone: widget.phone);
    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // -- Gradient Header --
            Container(
              width: double.infinity,
              height: screenHeight * 0.32,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // White back button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingBase),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sms_outlined,
                              size: 34,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingBase),
                          Text(
                            'Verify OTP',
                            style:
                                theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            'We sent a 6-digit code to',
                            style:
                                theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            widget.phone,
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing2xl),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Enter Verification Code',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // -- OTP Input --
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '------',
                        hintStyle:
                            theme.textTheme.headlineLarge?.copyWith(
                          color: AppTheme.textTertiary,
                          letterSpacing: 12,
                        ),
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide:
                              const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide:
                              const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length == 6) _verifyOtp();
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // -- Verify Button (gradient) --
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
                          onTap: isLoading ? null : _verifyOtp,
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
                                : const Text(
                                    'Verify',
                                    style: TextStyle(
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

                    // -- Resend Row --
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _canResend ? _resendOtp : null,
                          child: Text(
                            _canResend
                                ? 'Resend'
                                : 'Resend in ${_resendSeconds}s',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _canResend
                                  ? AppTheme.primary
                                  : AppTheme.textTertiary,
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
          ],
        ),
      ),
    );
  }
}
