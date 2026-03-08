class VendorOrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String status;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VendorOrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.items = const [],
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.totalAmount = 0,
    required this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory VendorOrderModel.fromJson(Map<String, dynamic> json) {
    return VendorOrderModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      customerId: json['customer'] is Map
          ? json['customer']['_id'] as String? ?? ''
          : json['customer'] as String? ?? '',
      customerName: json['customer'] is Map
          ? json['customer']['name'] as String? ?? 'Customer'
          : json['customerName'] as String? ?? 'Customer',
      customerPhone: json['customer'] is Map
          ? json['customer']['phone'] as String?
          : json['customerPhone'] as String?,
      customerAddress: json['deliveryAddress'] is Map
          ? '${json['deliveryAddress']['street'] ?? ''}, ${json['deliveryAddress']['city'] ?? ''}'
          : json['deliveryAddress'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0,
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
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
  bool get canPrepare => status == 'confirmed';
  bool get canMarkReady => status == 'preparing';
  bool get canMarkOutForDelivery => status == 'ready';
  bool get canDeliver => status == 'out_for_delivery';
  bool get canCancel => status == 'pending' || status == 'confirmed';
}

class OrderItemModel {
  final String id;
  final String productId;
  final String name;
  final String? image;
  final int quantity;
  final double price;
  final double total;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.name,
    this.image,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      productId: json['product'] is Map
          ? json['product']['_id'] as String? ?? ''
          : json['product'] as String? ?? '',
      name: json['product'] is Map
          ? json['product']['name'] as String? ?? ''
          : json['name'] as String? ?? '',
      image: json['product'] is Map
          ? (json['product']['images'] as List?)?.firstOrNull?.toString()
          : null,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ??
          ((json['price'] as num?)?.toDouble() ?? 0) *
              (json['quantity'] as int? ?? 1),
    );
  }
}
