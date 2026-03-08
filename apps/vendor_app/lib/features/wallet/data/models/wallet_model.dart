class WalletModel {
  final String id;
  final double balance;
  final double pendingPayout;
  final double totalEarnings;
  final double totalPayouts;

  const WalletModel({
    required this.id,
    this.balance = 0,
    this.pendingPayout = 0,
    this.totalEarnings = 0,
    this.totalPayouts = 0,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      pendingPayout: (json['pendingPayout'] as num?)?.toDouble() ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0,
      totalPayouts: (json['totalPayouts'] as num?)?.toDouble() ?? 0,
    );
  }
}

class WalletTransactionModel {
  final String id;
  final String type; // credit, debit
  final double amount;
  final String description;
  final String? referenceId;
  final String? referenceType;
  final String status;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.referenceId,
    this.referenceType,
    this.status = 'completed',
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      type: json['type'] as String? ?? 'credit',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      referenceId: json['referenceId'] as String?,
      referenceType: json['referenceType'] as String?,
      status: json['status'] as String? ?? 'completed',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';
}
