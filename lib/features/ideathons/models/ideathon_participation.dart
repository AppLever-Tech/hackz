import 'package:cloud_firestore/cloud_firestore.dart';

import '../../payment/models/payment_model.dart';
import 'ideathon_participation_status.dart';

/// Event membership: one document per (idea, ideathon).
///
/// The same Idea may join different Ideathons over time. Idea payment is
/// verified before create; this record does not drive a payment/pool lifecycle.
/// Ideathon/payment state is never stored on [IdeaStatus].
class IdeathonParticipation {
  const IdeathonParticipation({
    required this.participationId,
    required this.ideathonId,
    required this.ideaId,
    required this.orgId,
    required this.paymentStatus,
    required this.participationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String participationId;
  final String ideathonId;
  final String ideaId;
  final String orgId;

  /// Snapshot of this event's payment status (not idea-submission payment).
  final PaymentRecordStatus paymentStatus;

  /// Membership status for this Ideathon only.
  final IdeathonParticipationStatus participationStatus;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => participationStatus == IdeathonParticipationStatus.active;

  IdeathonParticipation copyWith({
    PaymentRecordStatus? paymentStatus,
    IdeathonParticipationStatus? participationStatus,
    DateTime? updatedAt,
  }) {
    return IdeathonParticipation(
      participationId: participationId,
      ideathonId: ideathonId,
      ideaId: ideaId,
      orgId: orgId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      participationStatus: participationStatus ?? this.participationStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'participationId': participationId,
      'ideathonId': ideathonId,
      'ideaId': ideaId,
      'orgId': orgId,
      'paymentStatus': paymentStatus.value,
      'participationStatus': participationStatus.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory IdeathonParticipation.fromMap(String id, Map<String, dynamic> map) {
    return IdeathonParticipation(
      participationId: ((map['participationId'] as String?) ?? '').trim().isNotEmpty
          ? (map['participationId'] as String).trim()
          : id,
      ideathonId: ((map['ideathonId'] as String?) ?? '').trim(),
      ideaId: ((map['ideaId'] as String?) ?? '').trim(),
      orgId: ((map['orgId'] as String?) ?? '').trim(),
      paymentStatus: PaymentRecordStatus.fromRaw((map['paymentStatus'] as String?) ?? 'pending'),
      participationStatus:
          IdeathonParticipationStatus.fromRaw((map['participationStatus'] as String?) ?? 'active'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
