class AssignmentModel {
  final String id;
  final String orderId;
  final String deliveryPartnerId;
  final String status;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? deliveryProofUrl;
  final String? deliveryOtp;
  final double? distanceKm;
  final double? earnings;
  final String? rejectionReason;
  final DateTime createdAt;

  // Order details (when available)
  final String? orderNumber;
  final String? vendorName;
  final String? vendorAddress;
  final String? customerName;
  final String? customerAddress;
  final double? orderTotal;

  const AssignmentModel({
    required this.id,
    required this.orderId,
    required this.deliveryPartnerId,
    required this.status,
    this.assignedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.deliveryProofUrl,
    this.deliveryOtp,
    this.distanceKm,
    this.earnings,
    this.rejectionReason,
    required this.createdAt,
    this.orderNumber,
    this.vendorName,
    this.vendorAddress,
    this.customerName,
    this.customerAddress,
    this.orderTotal,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      deliveryPartnerId: json['delivery_partner_id'] as String? ?? '',
      status: json['status'] as String? ?? 'assigned',
      assignedAt: _parseDateTime(json['assigned_at']),
      acceptedAt: _parseDateTime(json['accepted_at']),
      pickedUpAt: _parseDateTime(json['picked_up_at']),
      deliveredAt: _parseDateTime(json['delivered_at']),
      deliveryProofUrl: json['delivery_proof_url'] as String?,
      deliveryOtp: json['delivery_otp'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      earnings: (json['earnings'] as num?)?.toDouble(),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      orderNumber: json['order_number'] as String?,
      vendorName: json['vendor_name'] as String?,
      vendorAddress: json['vendor_address'] as String?,
      customerName: json['customer_name'] as String?,
      customerAddress: json['customer_address'] as String?,
      orderTotal: (json['order_total'] as num?)?.toDouble(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  bool get isAssigned => status == 'assigned';
  bool get isAccepted => status == 'accepted';
  bool get isPickedUp => status == 'picked_up';
  bool get isDelivered => status == 'delivered';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => isAssigned || isAccepted || isPickedUp;
}
