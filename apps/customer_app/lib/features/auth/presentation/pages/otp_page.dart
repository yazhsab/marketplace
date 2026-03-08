import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

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

  void _verifyOtp(String otp) {
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient Header (30% of screen) ─────────────────────────
            Container(
              width: double.infinity,
              height: screenHeight * 0.30,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: AppTheme.spacingSm),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXl),
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingBase),
                    Text(
                      'Verify OTP',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Code sent to ${widget.phone}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // ── White Card Body (overlaps gradient by 20px) ─────────────
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: screenHeight * 0.70 + 20,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: AppTheme.shadowLg,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXl,
                    vertical: AppTheme.spacing2xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Enter Verification Code',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'We have sent a 6-digit code to your phone number',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing3xl),

                      // ── OTP Input ─────────────────────────────────────
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: _otpController,
                        animationType: AnimationType.fade,
                        keyboardType: TextInputType.number,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          fieldHeight: 56,
                          fieldWidth: 48,
                          activeFillColor: Colors.white,
                          inactiveFillColor: AppTheme.surface,
                          selectedFillColor: Colors.white,
                          activeColor: AppTheme.primary,
                          inactiveColor: AppTheme.border,
                          selectedColor: AppTheme.primary,
                          borderWidth: 1,
                          activeBorderWidth: 2,
                          selectedBorderWidth: 2,
                        ),
                        enableActiveFill: true,
                        onCompleted: _verifyOtp,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: AppTheme.spacingXl),

                      // ── Gradient Verify Button ────────────────────────
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: isLoading
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primary.withValues(alpha: 0.6),
                                    AppTheme.gradientEnd
                                        .withValues(alpha: 0.6),
                                  ],
                                )
                              : AppTheme.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: isLoading
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoading
                                ? null
                                : () => _verifyOtp(_otpController.text),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
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
                                      'Verify',
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),

                      // ── Resend ────────────────────────────────────────
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
                              style: theme.textTheme.bodyMedium?.copyWith(
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
            ),
          ],
        ),
      ),
    );
  }
}
