class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String? categoryId;
  final String? categoryName;
  final List<String> images;
  final List<String> tags;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.durationMinutes = 60,
    this.categoryId,
    this.categoryName,
    this.images = const [],
    this.tags = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: json['durationMinutes'] as int? ?? json['duration'] as int? ?? 60,
      categoryId: json['category'] is Map
          ? json['category']['_id'] as String?
          : json['category'] as String?,
      categoryName:
          json['category'] is Map ? json['category']['name'] as String? : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'price': price,
        'durationMinutes': durationMinutes,
        if (categoryId != null) 'category': categoryId,
        if (tags.isNotEmpty) 'tags': tags,
        'isActive': isActive,
      };

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }
}
