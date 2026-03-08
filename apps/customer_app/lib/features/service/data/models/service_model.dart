class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String category;
  final String? subcategory;
  final List<String> images;
  final String vendorId;
  final String? vendorName;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final List<String> availableDays;
  final String? startTime;
  final String? endTime;
  final DateTime? createdAt;

  const ServiceModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.durationMinutes = 60,
    this.category = '',
    this.subcategory,
    this.images = const [],
    this.vendorId = '',
    this.vendorName,
    this.rating = 0,
    this.reviewCount = 0,
    this.isActive = true,
    this.availableDays = const [],
    this.startTime,
    this.endTime,
    this.createdAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: json['durationMinutes'] as int? ?? json['duration'] as int? ?? 60,
      category: json['category'] as String? ?? '',
      subcategory: json['subcategory'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      vendorId: json['vendorId'] as String? ?? json['vendor'] as String? ?? '',
      vendorName: json['vendorName'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ??
          (json['avgRating'] as num?)?.toDouble() ??
          0,
      reviewCount: json['reviewCount'] as int? ?? json['totalReviews'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      availableDays: (json['availableDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
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
      'durationMinutes': durationMinutes,
      'category': category,
      'subcategory': subcategory,
      'images': images,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'availableDays': availableDays,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  String get formattedDuration {
    if (durationMinutes < 60) return '$durationMinutes min';
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }
}
