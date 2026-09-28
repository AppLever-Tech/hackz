import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentRecordStatus {
  pending('pending'),
  verified('verified'),
  rejected('rejected');

  const PaymentRecordStatus(this.value);
  final String value;

  static PaymentRecordStatus fromRaw(String raw) {
    final n = raw.trim().toLowerCase();
    switch (n) {
      case 'verified':
        return PaymentRecordStatus.verified;
      case 'rejected':
        return PaymentRecordStatus.rejected;
      case 'pending':
      default:
        return PaymentRecordStatus.pending;
    }
  }
}

class PaymentModel {
  const PaymentModel({
    required this.paymentId,
    required this.ideaId,
    required this.teamId,
    required this.problemId,
    required this.problemNumber,
    required this.orgId,
    required this.departmentCode,
    required this.amount,
    required this.paymentProofUrl,
    required this.paidByStudentId,
    this.uploadedByAuthUid,
    required this.status,
    required this.verifiedBy,
    required this.verifiedAt,
    required this.remarks,
    required this.createdAt,
    this.transactionId,
    this.participationId = '',
    this.ideathonId = '',
  });

  final String paymentId;
  final String ideaId;
  final String teamId;
  final String problemId;
  final String problemNumber;
  final String orgId;
  final String departmentCode;
  final double amount;
  final String paymentProofUrl;
  final String paidByStudentId;
  final String? uploadedByAuthUid;
  final PaymentRecordStatus status;
  final String verifiedBy;
  final DateTime? verifiedAt;
  final String remarks;
  final DateTime createdAt;
  final String? transactionId;
  /// When set, payment is for event participation (not idea submission).
  final String participationId;
  /// Event id for this payment (Ideathon today; Hackathon later). Firestore field remains `ideathonId`.
  final String ideathonId;

  /// Event this payment is scoped to. Empty for idea-submission (department) payments.
  String get eventId => ideathonId.trim();

  bool get isEventScoped => eventId.isNotEmpty || participationId.trim().isNotEmpty;

  bool belongsToEvent(String eventId) {
    final String id = eventId.trim();
    return id.isNotEmpty && this.eventId == id;
  }

  bool get isIdeathonParticipationPayment => isEventScoped;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'paymentId': paymentId,
      'ideaId': ideaId,
      'teamId': teamId,
      'problemId': problemId,
      'problemNumber': problemNumber,
      'orgId': orgId,
      'departmentCode': departmentCode,
      'amount': amount,
      'paymentProofUrl': paymentProofUrl,
      'paidByStudentId': paidByStudentId,
      'uploadedByAuthUid': (uploadedByAuthUid ?? '').trim().isEmpty ? null : uploadedByAuthUid!.trim(),
      'status': status.value,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt == null ? null : Timestamp.fromDate(verifiedAt!),
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'transactionId': transactionId,
      if (participationId.trim().isNotEmpty) 'participationId': participationId.trim(),
      if (ideathonId.trim().isNotEmpty) 'ideathonId': ideathonId.trim(),
    };
  }

  factory PaymentModel.fromMap(String paymentId, Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: ((map['paymentId'] as String?) ?? '').trim().isNotEmpty
          ? (map['paymentId'] as String).trim()
          : paymentId,
      ideaId: ((map['ideaId'] as String?) ?? '').trim(),
      teamId: ((map['teamId'] as String?) ?? '').trim(),
      problemId: ((map['problemId'] as String?) ?? '').trim(),
      problemNumber: ((map['problemNumber'] as String?) ?? '').trim(),
      orgId: ((map['orgId'] as String?) ?? '').trim(),
      departmentCode: ((map['departmentCode'] as String?) ?? '').trim().toUpperCase(),
      amount: ((map['amount'] as num?) ?? 0).toDouble(),
      paymentProofUrl: ((map['paymentProofUrl'] as String?) ?? '').trim(),
      paidByStudentId: ((map['paidByStudentId'] as String?) ?? '').trim(),
      uploadedByAuthUid: ((map['uploadedByAuthUid'] as String?) ?? '').trim().isEmpty
          ? null
          : (map['uploadedByAuthUid'] as String).trim(),
      status: PaymentRecordStatus.fromRaw((map['status'] as String?) ?? 'pending'),
      verifiedBy: ((map['verifiedBy'] as String?) ?? '').trim(),
      verifiedAt: (map['verifiedAt'] as Timestamp?)?.toDate(),
      remarks: ((map['remarks'] as String?) ?? '').trim(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      transactionId: (map['transactionId'] as String?)?.trim(),
      participationId: ((map['participationId'] as String?) ?? '').trim(),
      ideathonId: ((map['ideathonId'] as String?) ?? '').trim(),
    );
  }

  PaymentModel copyWith({
    String? paymentId,
    String? ideaId,
    String? teamId,
    String? problemId,
    String? problemNumber,
    String? orgId,
    String? departmentCode,
    double? amount,
    String? paymentProofUrl,
    String? paidByStudentId,
    String? uploadedByAuthUid,
    PaymentRecordStatus? status,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? remarks,
    DateTime? createdAt,
    String? transactionId,
    String? participationId,
    String? ideathonId,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      ideaId: ideaId ?? this.ideaId,
      teamId: teamId ?? this.teamId,
      problemId: problemId ?? this.problemId,
      problemNumber: problemNumber ?? this.problemNumber,
      orgId: orgId ?? this.orgId,
      departmentCode: departmentCode ?? this.departmentCode,
      amount: amount ?? this.amount,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paidByStudentId: paidByStudentId ?? this.paidByStudentId,
      uploadedByAuthUid: uploadedByAuthUid ?? this.uploadedByAuthUid,
      status: status ?? this.status,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      transactionId: transactionId ?? this.transactionId,
      participationId: participationId ?? this.participationId,
      ideathonId: ideathonId ?? this.ideathonId,
    );
  }
}
