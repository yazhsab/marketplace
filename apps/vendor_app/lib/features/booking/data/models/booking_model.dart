class VendorBookingModel {
  final String id;
  final String bookingNumber;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final DateTime scheduledDate;
  final String scheduledTime;
  final int durationMinutes;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VendorBookingModel({
    required this.id,
    required this.bookingNumber,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.serviceId,
    required this.serviceName,
    this.servicePrice = 0,
    required this.scheduledDate,
    required this.scheduledTime,
    this.durationMinutes = 60,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory VendorBookingModel.fromJson(Map<String, dynamic> json) {
    return VendorBookingModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      bookingNumber: json['bookingNumber'] as String? ?? '',
      customerId: json['customer'] is Map
          ? json['customer']['_id'] as String? ?? ''
          : json['customer'] as String? ?? '',
      customerName: json['customer'] is Map
          ? json['customer']['name'] as String? ?? 'Customer'
          : json['customerName'] as String? ?? 'Customer',
      customerPhone: json['customer'] is Map
          ? json['customer']['phone'] as String?
          : json['customerPhone'] as String?,
      serviceId: json['service'] is Map
          ? json['service']['_id'] as String? ?? ''
          : json['service'] as String? ?? '',
      serviceName: json['service'] is Map
          ? json['service']['name'] as String? ?? ''
          : json['serviceName'] as String? ?? '',
      servicePrice: json['service'] is Map
          ? (json['service']['price'] as num?)?.toDouble() ?? 0
          : (json['amount'] as num?)?.toDouble() ?? 0,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      scheduledTime: json['scheduledTime'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  bool get canConfirm => status == 'pending';
  bool get canStart => status == 'confirmed';
  bool get canComplete => status == 'in_progress';
  bool get canCancel => status == 'pending' || status == 'confirmed';
  bool get isUpcoming =>
      scheduledDate.isAfter(DateTime.now()) && status != 'cancelled';
}
