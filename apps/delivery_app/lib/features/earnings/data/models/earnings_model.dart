class EarningsModel {
  final double totalEarnings;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final double walletBalance;
  final int totalDeliveries;

  const EarningsModel({
    this.totalEarnings = 0,
    this.todayEarnings = 0,
    this.weekEarnings = 0,
    this.monthEarnings = 0,
    this.walletBalance = 0,
    this.totalDeliveries = 0,
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 0,
      weekEarnings: (json['week_earnings'] as num?)?.toDouble() ?? 0,
      monthEarnings: (json['month_earnings'] as num?)?.toDouble() ?? 0,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
    );
  }
}

class EarningsHistoryItem {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String status;
  final DateTime createdAt;

  const EarningsHistoryItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.status = 'completed',
    required this.createdAt,
  });

  factory EarningsHistoryItem.fromJson(Map<String, dynamic> json) {
    return EarningsHistoryItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'credit',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isCredit => type == 'credit';
}
