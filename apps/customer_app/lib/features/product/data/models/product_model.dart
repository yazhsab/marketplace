class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? comparePrice;
  final String category;
  final String? subcategory;
  final List<String> images;
  final String vendorId;
  final String? vendorName;
  final int stockQuantity;
  final String? sku;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final Map<String, dynamic>? attributes;
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.comparePrice,
    this.category = '',
    this.subcategory,
    this.images = const [],
    this.vendorId = '',
    this.vendorName,
    this.stockQuantity = 0,
    this.sku,
    this.rating = 0,
    this.reviewCount = 0,
    this.isActive = true,
    this.attributes,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      comparePrice: (json['comparePrice'] as num?)?.toDouble(),
      category: json['category'] as String? ?? '',
      subcategory: json['subcategory'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vendorId: json['vendorId'] as String? ?? json['vendor'] as String? ?? '',
      vendorName: json['vendorName'] as String?,
      stockQuantity: json['stockQuantity'] as int? ?? json['stock'] as int? ?? 0,
      sku: json['sku'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ??
          (json['avgRating'] as num?)?.toDouble() ??
          0,
      reviewCount: json['reviewCount'] as int? ?? json['totalReviews'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      attributes: json['attributes'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'comparePrice': comparePrice,
      'category': category,
      'subcategory': subcategory,
      'images': images,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'stockQuantity': stockQuantity,
      'sku': sku,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'attributes': attributes,
    };
  }

  bool get inStock => stockQuantity > 0;

  bool get hasDiscount => comparePrice != null && comparePrice! > price;

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((comparePrice! - price) / comparePrice!) * 100).round();
  }
}
