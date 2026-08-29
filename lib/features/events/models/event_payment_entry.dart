import '../../payment/models/payment_model.dart';

/// Event-generic payment row (Ideathon idea payment; Hackathon prototype later).
class EventPaymentEntry {
  const EventPaymentEntry({
    required this.entryId,
    required this.entryTitle,
    required this.teamId,
    required this.teamName,
    required this.status,
    this.payerId = '',
    this.payerName = '',
    this.payment,
    this.canConfirm = false,
    this.canMarkException = false,
    this.proofCount = 0,
  });

  final String entryId;
  final String entryTitle;
  final String teamId;
  final String teamName;
  final String payerId;
  final String payerName;
  final PaymentModel? payment;
  final PaymentRecordStatus status;
  final bool canConfirm;
  final bool canMarkException;
  /// Active attachment count for this payment (screenshot / proof files).
  final int proofCount;

  bool get hasProof {
    if (proofCount > 0) return true;
    return (payment?.paymentProofUrl.trim().isNotEmpty ?? false);
  }

  String? get paymentId {
    final String id = (payment?.paymentId ?? '').trim();
    return id.isEmpty ? null : id;
  }
}

class EventPaymentMetrics {
  const EventPaymentMetrics({
    required this.total,
    required this.confirmed,
    required this.pending,
    required this.exceptions,
  });

  final int total;
  final int confirmed;
  final int pending;
  final int exceptions;
}
