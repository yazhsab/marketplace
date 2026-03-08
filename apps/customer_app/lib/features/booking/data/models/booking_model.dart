class BookingModel {
  final String id;
  final String bookingNumber;
  final String serviceId;
  final String serviceName;
  final String vendorId;
  final String? vendorName;
  final String status;
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;
  final double price;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? paymentId;
  final String? notes;
  final Map<String, dynamic>? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    required this.id,
    required this.bookingNumber,
    required this.serviceId,
    this.serviceName = '',
    this.vendorId = '',
    this.vendorName,
    required this.status,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.price,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentId,
    this.notes,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      bookingNumber: json['bookingNumber'] as String? ?? '',
      serviceId: json['serviceId'] as String? ?? json['service'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? json['vendor'] as String? ?? '',
      vendorName: json['vendorName'] as String?,
      status: json['status'] as String? ?? 'pending',
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'].toString())
          : DateTime.now(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      paymentId: json['paymentId'] as String?,
      notes: json['notes'] as String?,
      address: json['address'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  bool get isCancellable =>
      status == 'pending' || status == 'confirmed';

  bool get isUpcoming =>
      scheduledDate.isAfter(DateTime.now()) &&
      (status == 'pending' || status == 'confirmed');

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }
}
