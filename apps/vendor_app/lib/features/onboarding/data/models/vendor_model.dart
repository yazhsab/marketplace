class VendorModel {
  final String? id;
  final String? userId;
  final String? businessName;
  final String? businessType;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? logoUrl;
  final String? status;
  final double? commissionPercent;
  final double? serviceRadius;
  final bool isOnline;
  final Map<String, String>? documents;
  final DateTime? createdAt;

  const VendorModel({
    this.id,
    this.userId,
    this.businessName,
    this.businessType,
    this.description,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.logoUrl,
    this.status,
    this.commissionPercent,
    this.serviceRadius,
    this.isOnline = false,
    this.documents,
    this.createdAt,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String? ?? json['_id'] as String?,
      userId: json['userId'] as String?,
      businessName: json['businessName'] as String?,
      businessType: json['businessType'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      logoUrl: json['logoUrl'] as String? ?? json['logo'] as String?,
      status: json['status'] as String? ?? 'pending',
      commissionPercent: (json['commissionPercent'] as num?)?.toDouble(),
      serviceRadius: (json['serviceRadius'] as num?)?.toDouble(),
      isOnline: json['isOnline'] as bool? ?? false,
      documents: json['documents'] != null
          ? Map<String, String>.from(json['documents'] as Map)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (businessName != null) 'businessName': businessName,
      if (businessType != null) 'businessType': businessType,
      if (description != null) 'description': description,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (serviceRadius != null) 'serviceRadius': serviceRadius,
    };
  }

  VendorModel copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessType,
    String? description,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? logoUrl,
    String? status,
    double? commissionPercent,
    double? serviceRadius,
    bool? isOnline,
    Map<String, String>? documents,
    DateTime? createdAt,
  }) {
    return VendorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      isOnline: isOnline ?? this.isOnline,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
