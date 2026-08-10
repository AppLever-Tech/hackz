import 'package:cloud_firestore/cloud_firestore.dart';

import '../../payment/models/payment_model.dart';
import 'ideathon_participation_status.dart';

/// Event-specific Idea ↔ Ideathon relationship.
///
/// One document per (idea, ideathon). The same Idea may have many participations
/// across future events. Ideathon/payment state is never stored on [IdeaStatus].
///
/// - [IdeathonParticipationStatus.inPool]: idea is in the Ideathon pool only.
/// - [IdeathonParticipationStatus.paymentPending]: payment in progress.
/// - [IdeathonParticipationStatus.readyForExecution]: registered after payment.
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

  /// Payment record status mirrored for this participation (pending until paid).
  final PaymentRecordStatus paymentStatus;

  /// Pool vs payment vs registered state for this Ideathon only.
  final IdeathonParticipationStatus participationStatus;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// In the Ideathon event pool, not yet registered.
  bool get isInPool => participationStatus == IdeathonParticipationStatus.inPool;

  /// Registered for this Ideathon (payment verified + ready for execution).
  bool get isRegistered =>
      participationStatus == IdeathonParticipationStatus.readyForExecution &&
      paymentStatus == PaymentRecordStatus.verified;

  /// Alias for registered / execution-ready participation.
  bool get isReadyForExecution => isRegistered;

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
          IdeathonParticipationStatus.fromRaw((map['participationStatus'] as String?) ?? 'inPool'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
