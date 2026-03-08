import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  String _vehicleType = 'bike';
  final _vehicleNumberController = TextEditingController();
  final _licenseController = TextEditingController();
  final _zoneController = TextEditingController();
  int _currentStep = 0;

  final _vehicleTypes = ['bike', 'scooter', 'bicycle', 'car'];

  final _vehicleIcons = {
    'bike': Icons.two_wheeler,
    'scooter': Icons.electric_scooter,
    'bicycle': Icons.pedal_bike,
    'car': Icons.directions_car,
  };

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _licenseController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(onboardingProvider.notifier).register(
          vehicleType: _vehicleType,
          vehicleNumber: _vehicleNumberController.text.trim(),
          licenseNumber: _licenseController.text.trim(),
          zonePreference: _zoneController.text.trim().isNotEmpty
              ? _zoneController.text.trim()
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    ref.listen<OnboardingState>(onboardingProvider, (previous, next) {
      if (next.isRegistered) {
        context.showSuccessSnackBar(
            'Registration submitted! Awaiting admin approval.');
        context.go('/');
      } else if (next.error != null) {
        context.showSnackBar(next.error!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // -- Gradient Header --
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppTheme.spacingBase,
              bottom: AppTheme.spacing3xl + 20,
              left: AppTheme.spacingXl,
              right: AppTheme.spacingXl,
            ),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Become a Delivery Partner',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Complete your profile to start delivering',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          // -- Scrollable Card Body --
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingBase),
                  padding: const EdgeInsets.all(AppTheme.spacingXl),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    boxShadow: AppTheme.shadowLg,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // -- Step Indicator (dots + lines) --
                        _buildStepIndicator(theme),
                        const SizedBox(height: AppTheme.spacingXl),

                        // -- Step 1: Vehicle Details --
                        _buildSectionHeader(
                          theme,
                          icon: Icons.two_wheeler_outlined,
                          title: 'Vehicle Details',
                          stepNumber: 1,
                          isActive: _currentStep >= 0,
                        ),
                        const SizedBox(height: AppTheme.spacingBase),

                        // Vehicle Type Selector
                        Text(
                          'Vehicle Type',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Row(
                          children: _vehicleTypes.map((type) {
                            final isSelected = _vehicleType == type;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _vehicleType = type),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(
                                    right: type != _vehicleTypes.last
                                        ? AppTheme.spacingSm
                                        : 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppTheme.spacingMd),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary
                                            .withValues(alpha: 0.1)
                                        : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        _vehicleIcons[type] ??
                                            Icons.two_wheeler,
                                        color: isSelected
                                            ? AppTheme.primary
                                            : AppTheme.textSecondary,
                                        size: 24,
                                      ),
                                      const SizedBox(
                                          height: AppTheme.spacingXs),
                                      Text(
                                        type.capitalize,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: isSelected
                                              ? AppTheme.primary
                                              : AppTheme.textSecondary,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppTheme.spacingBase),

                        // Vehicle Number
                        Text(
                          'Vehicle Number',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        TextFormField(
                          controller: _vehicleNumberController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'e.g., KA01AB1234',
                            prefixIcon: Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: const Icon(Icons.badge_outlined,
                                  color: AppTheme.textSecondary, size: 20),
                            ),
                          ),
                          onChanged: (_) {
                            if (_currentStep < 1) {
                              setState(() => _currentStep = 1);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your vehicle number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingXl),

                        // -- Step 2: Documents --
                        _buildSectionHeader(
                          theme,
                          icon: Icons.description_outlined,
                          title: 'Documents',
                          stepNumber: 2,
                          isActive: _currentStep >= 1,
                        ),
                        const SizedBox(height: AppTheme.spacingBase),

                        // License Number
                        Text(
                          'Driving License Number',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        TextFormField(
                          controller: _licenseController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Enter your license number',
                            prefixIcon: Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: const Icon(
                                  Icons.credit_card_outlined,
                                  color: AppTheme.textSecondary,
                                  size: 20),
                            ),
                          ),
                          onChanged: (_) {
                            if (_currentStep < 2) {
                              setState(() => _currentStep = 2);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your license number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingBase),

                        // Document Upload with dashed border
                        _buildUploadArea(theme),
                        const SizedBox(height: AppTheme.spacingXl),

                        // -- Step 3: Preferences --
                        _buildSectionHeader(
                          theme,
                          icon: Icons.tune_outlined,
                          title: 'Preferences',
                          stepNumber: 3,
                          isActive: _currentStep >= 2,
                        ),
                        const SizedBox(height: AppTheme.spacingBase),

                        // Zone Preference
                        Text(
                          'Zone Preference (Optional)',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        TextFormField(
                          controller: _zoneController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Koramangala, HSR Layout',
                            prefixIcon: Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppTheme.textSecondary,
                                  size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing2xl),

                        // -- Submit Button (gradient) --
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: state.isLoading
                                ? null
                                : AppTheme.primaryGradient,
                            color: state.isLoading
                                ? AppTheme.primary
                                    .withValues(alpha: 0.5)
                                : null,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                            boxShadow: state.isLoading
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
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLg),
                              onTap: state.isLoading
                                  ? null
                                  : _handleRegister,
                              child: Center(
                                child: state.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Submit Registration',
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
                        const SizedBox(height: AppTheme.spacingBase),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Row(
      children: List.generate(3, (index) {
        final isCompleted = _currentStep > index;
        final isActive = _currentStep == index;
        return Expanded(
          child: Row(
            children: [
              // Dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.primary
                      : isActive
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : AppTheme.border,
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: AppTheme.primary, width: 2)
                      : null,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 8, color: Colors.white)
                    : null,
              ),
              // Line
              if (index < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primary
                          : AppTheme.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildUploadArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppTheme.primary.withValues(alpha: 0.3),
          borderRadius: AppTheme.radiusMd,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 24,
                color: AppTheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Upload License Photo',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'JPG, PNG up to 5MB',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required int stepNumber,
    required bool isActive,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary
                : AppTheme.textTertiary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isActive ? Colors.white : AppTheme.textTertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Icon(
          icon,
          color: isActive ? AppTheme.primary : AppTheme.textTertiary,
          size: 20,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isActive ? AppTheme.textPrimary : AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    const dashLength = 6.0;
    const gapLength = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
