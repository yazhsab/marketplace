import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  String _selectedBusinessType = 'both';
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  final _stepLabels = const [
    'Business',
    'Address',
    'Documents',
    'Review',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Vendor Onboarding'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Logout'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Step indicator at top
          _buildStepIndicator(onboardingState.currentStep, theme),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: _buildStepContent(onboardingState, theme),
            ),
          ),

          // Bottom action buttons
          if (!onboardingState.isSubmitted)
            _buildBottomButtons(onboardingState, theme),
        ],
      ),
    );
  }

  // ── Step Indicator ──────────────────────────────────────────────────────

  Widget _buildStepIndicator(int currentStep, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXl,
        vertical: AppTheme.spacingLg,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: List.generate(_stepLabels.length, (index) {
          final isCompleted = currentStep > index;
          final isActive = currentStep == index;
          final isLast = index == _stepLabels.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dot
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppTheme.primary
                              : isActive
                                  ? AppTheme.primary
                                  : AppTheme.surface,
                          border: Border.all(
                            color: isCompleted || isActive
                                ? AppTheme.primary
                                : AppTheme.border,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : AppTheme.textTertiary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        _stepLabels[index],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isCompleted || isActive
                              ? AppTheme.primary
                              : AppTheme.textTertiary,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(
                          bottom: AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.primary
                            : AppTheme.border,
                        borderRadius:
                            BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step Content ────────────────────────────────────────────────────────

  Widget _buildStepContent(
      OnboardingState onboardingState, ThemeData theme) {
    switch (onboardingState.currentStep) {
      case 0:
        return _buildBusinessInfoStep(theme);
      case 1:
        return _buildAddressStep(theme);
      case 2:
        return _buildDocumentsStep(onboardingState, theme);
      case 3:
        return _buildReviewStep(onboardingState, theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Business Info Step ──────────────────────────────────────────────────

  Widget _buildBusinessInfoStep(ThemeData theme) {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Business Information',
              'Tell us about your business'),
          const SizedBox(height: AppTheme.spacingLg),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name *',
                    prefixIcon: Icon(Icons.storefront_rounded),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Business name is required'
                      : null,
                ),
                const SizedBox(height: AppTheme.spacingBase),
                DropdownButtonFormField<String>(
                  value: _selectedBusinessType,
                  decoration: const InputDecoration(
                    labelText: 'Business Type *',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'product', child: Text('Product Seller')),
                    DropdownMenuItem(
                        value: 'service', child: Text('Service Provider')),
                    DropdownMenuItem(
                        value: 'both', child: Text('Products & Services')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedBusinessType = v);
                  },
                ),
                const SizedBox(height: AppTheme.spacingBase),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    prefixIcon: Icon(Icons.description_rounded),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Description is required'
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Address Step ────────────────────────────────────────────────────────

  Widget _buildAddressStep(ThemeData theme) {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              theme, 'Business Address', 'Where is your business located?'),
          const SizedBox(height: AppTheme.spacingLg),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Full Address *',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  maxLines: 2,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Address is required'
                      : null,
                ),
                const SizedBox(height: AppTheme.spacingBase),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration:
                            const InputDecoration(labelText: 'City *'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration:
                            const InputDecoration(labelText: 'State *'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingBase),
                TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode *',
                    prefixIcon: Icon(Icons.pin_drop_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Pincode is required';
                    if (v.length != 6) return 'Enter valid 6-digit pincode';
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingBase),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration:
                            const InputDecoration(labelText: 'Latitude'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration:
                            const InputDecoration(labelText: 'Longitude'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Documents Step ──────────────────────────────────────────────────────

  Widget _buildDocumentsStep(
      OnboardingState onboardingState, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Verification Documents',
            'Upload required documents for verification'),
        const SizedBox(height: AppTheme.spacingLg),
        _buildDocUploadCard(
          theme: theme,
          title: 'Aadhaar Card',
          subtitle: 'Upload front side of your Aadhaar',
          icon: Icons.credit_card_rounded,
          isUploaded: onboardingState.aadhaarPath != null,
          onTap: () =>
              ref.read(onboardingProvider.notifier).pickDocument('aadhaar'),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _buildDocUploadCard(
          theme: theme,
          title: 'PAN Card',
          subtitle: 'Upload your PAN card',
          icon: Icons.badge_rounded,
          isUploaded: onboardingState.panPath != null,
          onTap: () =>
              ref.read(onboardingProvider.notifier).pickDocument('pan'),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _buildDocUploadCard(
          theme: theme,
          title: 'GST Certificate (Optional)',
          subtitle: 'Upload GST registration certificate',
          icon: Icons.receipt_rounded,
          isUploaded: onboardingState.gstPath != null,
          onTap: () =>
              ref.read(onboardingProvider.notifier).pickDocument('gst'),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _buildDocUploadCard(
          theme: theme,
          title: 'Bank Proof',
          subtitle: 'Cancelled cheque or passbook',
          icon: Icons.account_balance_rounded,
          isUploaded: onboardingState.bankProofPath != null,
          onTap: () => ref
              .read(onboardingProvider.notifier)
              .pickDocument('bank_proof'),
        ),
      ],
    );
  }

  Widget _buildDocUploadCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isUploaded
              ? AppTheme.successColor.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUploaded
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              isUploaded ? Icons.check_circle_rounded : icon,
              color: isUploaded ? AppTheme.successColor : AppTheme.textTertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  isUploaded ? 'File selected' : subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isUploaded
                        ? AppTheme.successColor
                        : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Upload/Change button
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: isUploaded
                    ? AppTheme.surface
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                isUploaded ? 'Change' : 'Upload',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isUploaded
                      ? AppTheme.textSecondary
                      : AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Review Step ─────────────────────────────────────────────────────────

  Widget _buildReviewStep(
      OnboardingState onboardingState, ThemeData theme) {
    if (onboardingState.isSubmitted) {
      return _buildVerificationPending(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Review & Submit',
            'Verify your information before submitting'),
        const SizedBox(height: AppTheme.spacingLg),

        // Business Info review card
        _buildReviewCard(
          theme,
          icon: Icons.storefront_rounded,
          iconColor: AppTheme.primary,
          title: 'Business Info',
          items: [
            _ReviewItem('Name', onboardingState.businessName),
            _ReviewItem('Type', onboardingState.businessType),
            _ReviewItem('Description', onboardingState.description),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Address review card
        _buildReviewCard(
          theme,
          icon: Icons.location_on_rounded,
          iconColor: AppTheme.secondary,
          title: 'Address',
          items: [
            _ReviewItem('Address', onboardingState.address),
            _ReviewItem('City', onboardingState.city),
            _ReviewItem('State', onboardingState.state),
            _ReviewItem('Pincode', onboardingState.pincode),
            if (onboardingState.latitude.isNotEmpty)
              _ReviewItem('Location',
                  '${onboardingState.latitude}, ${onboardingState.longitude}'),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Documents review card
        _buildReviewCard(
          theme,
          icon: Icons.folder_rounded,
          iconColor: AppTheme.warningColor,
          title: 'Documents',
          items: [
            _ReviewItem('Aadhaar',
                onboardingState.aadhaarPath != null ? 'Uploaded' : 'Not uploaded'),
            _ReviewItem('PAN',
                onboardingState.panPath != null ? 'Uploaded' : 'Not uploaded'),
            _ReviewItem('GST',
                onboardingState.gstPath != null ? 'Uploaded' : 'Not uploaded'),
            _ReviewItem(
                'Bank Proof',
                onboardingState.bankProofPath != null
                    ? 'Uploaded'
                    : 'Not uploaded'),
          ],
        ),

        if (onboardingState.error != null) ...[
          const SizedBox(height: AppTheme.spacingBase),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.error, size: 20),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    onboardingState.error!,
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  Widget _buildReviewCard(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<_ReviewItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        item.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value.isEmpty ? '-' : item.value,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildVerificationPending(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4xl),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              'Verification Pending',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacing2xl),
              child: Text(
                'Your application has been submitted and is under review. We will notify you once it is approved.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Buttons ──────────────────────────────────────────────────────

  Widget _buildBottomButtons(
      OnboardingState onboardingState, ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingBase,
        AppTheme.spacingMd,
        AppTheme.spacingBase,
        MediaQuery.of(context).padding.bottom + AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(
          top: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (onboardingState.currentStep > 0) ...[
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        ref.read(onboardingProvider.notifier).previousStep(),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLg),
                    child: Center(
                      child: Text(
                        'Back',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
          ],
          // Next/Submit gradient button
          Expanded(
            flex: onboardingState.currentStep > 0 ? 2 : 1,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: onboardingState.isLoading
                    ? LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.6),
                          const Color(0xFF60A5FA).withValues(alpha: 0.6),
                        ],
                      )
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onboardingState.isLoading
                      ? null
                      : () => _handleStepContinue(onboardingState),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusLg),
                  child: Center(
                    child: onboardingState.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                onboardingState.currentStep == 3
                                    ? 'Submit Application'
                                    : 'Continue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (onboardingState.currentStep < 3) ...[
                                const SizedBox(width: AppTheme.spacingSm),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 20),
                              ],
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

  // ── Section Header ──────────────────────────────────────────────────────

  Widget _buildSectionHeader(
      ThemeData theme, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Step Logic ──────────────────────────────────────────────────────────

  void _handleStepContinue(OnboardingState onboardingState) {
    final notifier = ref.read(onboardingProvider.notifier);

    switch (onboardingState.currentStep) {
      case 0:
        if (_formKeys[0].currentState?.validate() ?? false) {
          notifier.updateBusinessInfo(
            businessName: _businessNameController.text.trim(),
            businessType: _selectedBusinessType,
            description: _descriptionController.text.trim(),
          );
          notifier.nextStep();
        }
        break;
      case 1:
        if (_formKeys[1].currentState?.validate() ?? false) {
          notifier.updateAddress(
            address: _addressController.text.trim(),
            city: _cityController.text.trim(),
            stateVal: _stateController.text.trim(),
            pincode: _pincodeController.text.trim(),
            latitude: _latController.text.trim(),
            longitude: _lngController.text.trim(),
          );
          notifier.nextStep();
        }
        break;
      case 2:
        notifier.nextStep();
        break;
      case 3:
        notifier.submitRegistration();
        break;
    }
  }
}

class _ReviewItem {
  final String label;
  final String value;

  _ReviewItem(this.label, this.value);
}
