import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());
  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto-focus first pin field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNodes[0].requestFocus();
    });
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

  String get _otpValue =>
      _pinControllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final n in _pinFocusNodes) {
      n.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _verifyOtp() {
    final otp = _otpValue;
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

  void _onPinChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _pinFocusNodes[index + 1].requestFocus();
    }
    if (_otpValue.length == 6) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);

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
      body: Stack(
        children: [
          // Gradient header
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // White back button at top-left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppTheme.spacingXs),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // SMS icon in semi-transparent circle
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
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
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'We sent a 6-digit code to',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    widget.phone,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter Verification Code',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // OTP Pin Fields -- 6 individual boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 48,
                          height: 56,
                          margin: EdgeInsets.only(
                            right: index < 5 ? AppTheme.spacingSm : 0,
                          ),
                          child: TextFormField(
                            controller: _pinControllers[index],
                            focusNode: _pinFocusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: _pinControllers[index].text.isNotEmpty
                                  ? AppTheme.primary.withValues(alpha: 0.05)
                                  : AppTheme.surface,
                              contentPadding: EdgeInsets.zero,
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
                            onChanged: (v) => _onPinChanged(index, v),
                            onTap: () {
                              _pinControllers[index].selection =
                                  TextSelection.fromPosition(TextPosition(
                                      offset: _pinControllers[index]
                                          .text
                                          .length));
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppTheme.spacing2xl),

                    // Gradient Verify Button (52px)
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
                          onTap: isLoading ? null : _verifyOtp,
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

                    // Resend link with countdown timer
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
          ),
        ],
      ),
    );
  }
}
