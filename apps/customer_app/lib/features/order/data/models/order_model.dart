class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? paymentId;
  final OrderAddress? deliveryAddress;
  final String? vendorId;
  final String? vendorName;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? estimatedDelivery;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.items = const [],
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.tax = 0,
    this.total = 0,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentId,
    this.deliveryAddress,
    this.vendorId,
    this.vendorName,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.estimatedDelivery,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      paymentId: json['paymentId'] as String?,
      deliveryAddress: json['deliveryAddress'] != null
          ? OrderAddress.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
          : null,
      vendorId: json['vendorId'] as String?,
      vendorName: json['vendorName'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.tryParse(json['estimatedDelivery'].toString())
          : null,
    );
  }

  bool get isCancellable =>
      status == 'pending' || status == 'confirmed';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }
}

class OrderItemModel {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? image;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] as String? ?? json['product'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
    };
  }

  double get total => price * quantity;
}

class OrderAddress {
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? phone;

  const OrderAddress({
    this.label = 'Home',
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.phone,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      label: json['label'] as String? ?? 'Home',
      addressLine1: json['addressLine1'] as String? ?? json['street'] as String? ?? '',
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? json['zipCode'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
    };
  }

  String get fullAddress {
    final parts = [addressLine1];
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      parts.add(addressLine2!);
    }
    parts.addAll([city, state, pincode]);
    return parts.join(', ');
  }
}
