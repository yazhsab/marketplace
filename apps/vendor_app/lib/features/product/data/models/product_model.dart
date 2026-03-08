import 'dart:ui';

class ProductModel {
  final String id;
  final String name;
  final String? slug;
  final String description;
  final double price;
  final double? comparePrice;
  final String? unit;
  final String? sku;
  final String? categoryId;
  final String? categoryName;
  final List<String> images;
  final int stock;
  final int? lowStockThreshold;
  final List<String> tags;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.slug,
    required this.description,
    required this.price,
    this.comparePrice,
    this.unit,
    this.sku,
    this.categoryId,
    this.categoryName,
    this.images = const [],
    this.stock = 0,
    this.lowStockThreshold,
    this.tags = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      comparePrice: (json['comparePrice'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      sku: json['sku'] as String?,
      categoryId: json['category'] is Map
          ? json['category']['_id'] as String?
          : json['category'] as String?,
      categoryName:
          json['category'] is Map ? json['category']['name'] as String? : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      stock: json['stock'] as int? ?? 0,
      lowStockThreshold: json['lowStockThreshold'] as int?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (slug != null) 'slug': slug,
      'description': description,
      'price': price,
      if (comparePrice != null) 'comparePrice': comparePrice,
      if (unit != null) 'unit': unit,
      if (sku != null) 'sku': sku,
      if (categoryId != null) 'category': categoryId,
      'stock': stock,
      if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
      if (tags.isNotEmpty) 'tags': tags,
      'isActive': isActive,
    };
  }

  bool get isLowStock =>
      stock > 0 &&
      stock <= (lowStockThreshold ?? 5);
  bool get isOutOfStock => stock <= 0;
  bool get hasDiscount => comparePrice != null && comparePrice! > price;
  double get discountPercentage =>
      hasDiscount ? ((comparePrice! - price) / comparePrice! * 100) : 0;

  Color get stockColor {
    if (isOutOfStock) return const Color(0xFFD32F2F);
    if (isLowStock) return const Color(0xFFF9A825);
    return const Color(0xFF2E7D32);
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String? icon;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }
}
