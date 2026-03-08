class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? image;
  final String vendorId;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    required this.vendorId,
  });

  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    String? image,
    String? vendorId,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      vendorId: vendorId ?? this.vendorId,
    );
  }

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'vendorId': vendorId,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      image: json['image'] as String?,
      vendorId: json['vendorId'] as String,
    );
  }
}
