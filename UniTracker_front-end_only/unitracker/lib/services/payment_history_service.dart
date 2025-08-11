import 'package:flutter/foundation.dart';
import 'package:unitracker/models/payment_history.dart';
import 'package:unitracker/services/supabase_service.dart';

class PaymentHistoryService {
  static final PaymentHistoryService _instance =
      PaymentHistoryService._internal();
  factory PaymentHistoryService() => _instance;
  PaymentHistoryService._internal();

  List<PaymentHistory> _paymentHistory = [];

  List<PaymentHistory> get paymentHistory => List.unmodifiable(_paymentHistory);

  Future<void> loadPaymentHistory(String userId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('payment_history')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final historyData = response as List<dynamic>? ?? [];
      _paymentHistory =
          historyData.map((item) => PaymentHistory.fromJson(item)).toList();

      debugPrint('✅ Loaded ${_paymentHistory.length} payment history records');
    } catch (e) {
      debugPrint('❌ Error loading payment history: $e');
      rethrow;
    }
  }

  Future<void> addPaymentRecord({
    required String userId,
    required String cardId,
    required double amount,
    required String currency,
    required String status,
    required String description,
    String? reservationId,
  }) async {
    try {
      final response = await SupabaseService.instance.client
          .from('payment_history')
          .insert({
            'user_id': userId,
            'card_id': cardId,
            'amount': amount,
            'currency': currency,
            'status': status,
            'description': description,
            'reservation_id': reservationId,
          })
          .select()
          .single();

      final newPayment = PaymentHistory.fromJson(response);
      _paymentHistory.insert(0, newPayment);

      debugPrint('✅ Payment record added to history');
    } catch (e) {
      debugPrint('❌ Error adding payment record: $e');
      rethrow;
    }
  }

  List<PaymentHistory> getRecentPayments({int limit = 5}) {
    return _paymentHistory.take(limit).toList();
  }

  List<PaymentHistory> getPaymentsByStatus(String status) {
    return _paymentHistory
        .where((payment) => payment.status == status)
        .toList();
  }

  double getTotalSpent() {
    return _paymentHistory
        .where((payment) => payment.status == 'completed')
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  void clearCache() {
    _paymentHistory.clear();
  }
}
