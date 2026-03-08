class DeliveryPartnerModel {
  final String id;
  final String userId;
  final String vehicleType;
  final String? vehicleNumber;
  final String? licenseNumber;
  final String status;
  final bool isAvailable;
  final bool isOnShift;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? currentOrderId;
  final String? zonePreference;
  final double avgRating;
  final int totalDeliveries;
  final double totalEarnings;
  final double commissionPct;
  final DateTime createdAt;

  const DeliveryPartnerModel({
    required this.id,
    required this.userId,
    required this.vehicleType,
    this.vehicleNumber,
    this.licenseNumber,
    required this.status,
    this.isAvailable = false,
    this.isOnShift = false,
    this.currentLatitude,
    this.currentLongitude,
    this.currentOrderId,
    this.zonePreference,
    this.avgRating = 0,
    this.totalDeliveries = 0,
    this.totalEarnings = 0,
    this.commissionPct = 10,
    required this.createdAt,
  });

  factory DeliveryPartnerModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? 'bike',
      vehicleNumber: json['vehicle_number'] as String?,
      licenseNumber: json['license_number'] as String?,
      status: json['status'] as String? ?? 'pending',
      isAvailable: json['is_available'] as bool? ?? false,
      isOnShift: json['is_on_shift'] as bool? ?? false,
      currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
      currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
      currentOrderId: json['current_order_id'] as String?,
      zonePreference: json['zone_preference'] as String?,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      commissionPct: (json['commission_pct'] as num?)?.toDouble() ?? 10,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';
  bool get hasActiveOrder => currentOrderId != null;
}
