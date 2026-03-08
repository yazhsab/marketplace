class ReviewModel {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final int rating;
  final String? comment;
  final String? reply;
  final DateTime? repliedAt;
  final String? productId;
  final String? productName;
  final String? serviceId;
  final String? serviceName;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.rating,
    this.comment,
    this.reply,
    this.repliedAt,
    this.productId,
    this.productName,
    this.serviceId,
    this.serviceName,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['_id'] ?? '',
      customerId: json['customer'] is Map
          ? json['customer']['_id'] ?? ''
          : json['customer'] ?? '',
      customerName: json['customer'] is Map
          ? json['customer']['name'] ?? 'Customer'
          : json['customerName'] ?? 'Customer',
      customerAvatar:
          json['customer'] is Map ? json['customer']['avatar'] : null,
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      reply: json['reply'],
      repliedAt: json['repliedAt'] != null
          ? DateTime.parse(json['repliedAt'])
          : null,
      productId: json['product'] is Map
          ? json['product']['_id']
          : json['product'],
      productName:
          json['product'] is Map ? json['product']['name'] : null,
      serviceId: json['service'] is Map
          ? json['service']['_id']
          : json['service'],
      serviceName:
          json['service'] is Map ? json['service']['name'] : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  bool get hasReply => reply != null && reply!.isNotEmpty;
  String get itemName => productName ?? serviceName ?? 'Item';
}
