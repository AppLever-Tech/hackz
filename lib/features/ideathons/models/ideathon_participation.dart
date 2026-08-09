import 'package:cloud_firestore/cloud_firestore.dart';

import '../../payment/models/payment_model.dart';
import 'ideathon_participation_status.dart';

/// Relationship between an [Idea] and a specific Ideathon event.
///
/// Allows the same Idea to participate in multiple future events without
/// storing event state on the Idea itself.
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
  final PaymentRecordStatus paymentStatus;
  final IdeathonParticipationStatus participationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isReadyForExecution =>
      participationStatus == IdeathonParticipationStatus.readyForExecution &&
      paymentStatus == PaymentRecordStatus.verified;

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
          IdeathonParticipationStatus.fromRaw((map['participationStatus'] as String?) ?? 'paymentPending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
