import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/vendor_model.dart';

class OnboardingState {
  final int currentStep;
  final bool isLoading;
  final String? error;
  final bool isSubmitted;

  // Step 1: Business Info
  final String businessName;
  final String businessType;
  final String description;

  // Step 2: Address
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String latitude;
  final String longitude;

  // Step 3: Documents
  final String? aadhaarPath;
  final String? panPath;
  final String? gstPath;
  final String? bankProofPath;

  // Vendor status after submission
  final String? vendorStatus;

  const OnboardingState({
    this.currentStep = 0,
    this.isLoading = false,
    this.error,
    this.isSubmitted = false,
    this.businessName = '',
    this.businessType = 'both',
    this.description = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.latitude = '',
    this.longitude = '',
    this.aadhaarPath,
    this.panPath,
    this.gstPath,
    this.bankProofPath,
    this.vendorStatus,
  });

  OnboardingState copyWith({
    int? currentStep,
    bool? isLoading,
    String? error,
    bool? isSubmitted,
    String? businessName,
    String? businessType,
    String? description,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? latitude,
    String? longitude,
    String? aadhaarPath,
    String? panPath,
    String? gstPath,
    String? bankProofPath,
    String? vendorStatus,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      aadhaarPath: aadhaarPath ?? this.aadhaarPath,
      panPath: panPath ?? this.panPath,
      gstPath: gstPath ?? this.gstPath,
      bankProofPath: bankProofPath ?? this.bankProofPath,
      vendorStatus: vendorStatus ?? this.vendorStatus,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingState());

  void updateBusinessInfo({
    required String businessName,
    required String businessType,
    required String description,
  }) {
    state = state.copyWith(
      businessName: businessName,
      businessType: businessType,
      description: description,
    );
  }

  void updateAddress({
    required String address,
    required String city,
    required String stateVal,
    required String pincode,
    required String latitude,
    required String longitude,
  }) {
    state = state.copyWith(
      address: address,
      city: city,
      state: stateVal,
      pincode: pincode,
      latitude: latitude,
      longitude: longitude,
    );
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> pickDocument(String type) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) {
      switch (type) {
        case 'aadhaar':
          state = state.copyWith(aadhaarPath: image.path);
          break;
        case 'pan':
          state = state.copyWith(panPath: image.path);
          break;
        case 'gst':
          state = state.copyWith(gstPath: image.path);
          break;
        case 'bank_proof':
          state = state.copyWith(bankProofPath: image.path);
          break;
      }
    }
  }

  Future<String?> _uploadFile(String filePath) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await apiClient.uploadFile(
        ApiEndpoints.uploadMedia,
        formData: formData,
      );
      return response.data['data']?['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> submitRegistration() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);

      // Upload documents
      final Map<String, String> documentUrls = {};
      if (state.aadhaarPath != null) {
        final url = await _uploadFile(state.aadhaarPath!);
        if (url != null) documentUrls['aadhaar'] = url;
      }
      if (state.panPath != null) {
        final url = await _uploadFile(state.panPath!);
        if (url != null) documentUrls['pan'] = url;
      }
      if (state.gstPath != null) {
        final url = await _uploadFile(state.gstPath!);
        if (url != null) documentUrls['gst'] = url;
      }
      if (state.bankProofPath != null) {
        final url = await _uploadFile(state.bankProofPath!);
        if (url != null) documentUrls['bank_proof'] = url;
      }

      // Submit vendor registration
      final vendor = VendorModel(
        businessName: state.businessName,
        businessType: state.businessType,
        description: state.description,
        address: state.address,
        city: state.city,
        state: state.state,
        pincode: state.pincode,
        latitude: double.tryParse(state.latitude),
        longitude: double.tryParse(state.longitude),
        documents: documentUrls,
      );

      await apiClient.post(
        ApiEndpoints.vendorRegister,
        data: {
          ...vendor.toJson(),
          'documents': documentUrls,
        },
      );

      state = state.copyWith(
        isLoading: false,
        isSubmitted: true,
        vendorStatus: 'pending_verification',
        currentStep: 3,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref);
});
