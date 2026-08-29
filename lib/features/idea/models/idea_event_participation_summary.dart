import '../../payment/models/payment_model.dart';

/// Compact view of one idea's membership in a specific event.
class IdeaEventParticipationSummary {
  const IdeaEventParticipationSummary({
    required this.eventId,
    required this.eventName,
    required this.paymentStatus,
    this.evaluated = false,
    this.eventScore,
  });

  final String eventId;
  final String eventName;
  final PaymentRecordStatus paymentStatus;
  final bool evaluated;
  final double? eventScore;

  String get paymentLabel => switch (paymentStatus) {
        PaymentRecordStatus.verified => 'Paid',
        PaymentRecordStatus.pending => 'Pending',
        PaymentRecordStatus.rejected => 'Rejected',
      };

  String get evaluationLabel => evaluated ? 'Evaluated' : 'Pending';

  String? get scoreLabel {
    final double? score = eventScore;
    if (!evaluated || score == null) return null;
    return score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1);
  }
}
