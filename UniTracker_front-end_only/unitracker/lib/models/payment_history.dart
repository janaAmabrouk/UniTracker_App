class PaymentHistory {
  final String id;
  final String userId;
  final String cardId;
  final double amount;
  final String currency;
  final String status;
  final String description;
  final DateTime createdAt;
  final String? reservationId;

  PaymentHistory({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    required this.createdAt,
    this.reservationId,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      cardId: json['card_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      reservationId: json['reservation_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'card_id': cardId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'reservation_id': reservationId,
    };
  }
}
