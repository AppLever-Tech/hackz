import 'package:flutter/material.dart';

import 'package:hackz/constants/app_icons.dart';

import '../models/payment_model.dart';

/// Shared payment status visuals and finance timing rules.
class PaymentFinanceHelpers {
  PaymentFinanceHelpers._();

  static const Duration overdueThreshold = Duration(hours: 48);
  static const Duration recentlyVerifiedWindow = Duration(days: 7);

  static bool isOverdue(PaymentModel payment) {
    return payment.status == PaymentRecordStatus.pending &&
        DateTime.now().difference(payment.createdAt) > overdueThreshold;
  }

  static bool isRecentlyVerified(PaymentModel payment) {
    if (payment.status != PaymentRecordStatus.verified) return false;
    final at = payment.verifiedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) <= recentlyVerifiedWindow;
  }

  static bool needsAttention(PaymentModel payment, {required bool hasProof}) {
    if (payment.status != PaymentRecordStatus.pending) return false;
    return isOverdue(payment) || !hasProof;
  }

  static String statusLabel(PaymentRecordStatus status) {
    switch (status) {
      case PaymentRecordStatus.pending:
        return 'Pending';
      case PaymentRecordStatus.verified:
        return 'Verified';
      case PaymentRecordStatus.rejected:
        return 'Rejected';
    }
  }

  static IconData statusIcon(PaymentRecordStatus status) {
    switch (status) {
      case PaymentRecordStatus.pending:
        return AppIcons.statusUnderReview;
      case PaymentRecordStatus.verified:
        return AppIcons.statusApproved;
      case PaymentRecordStatus.rejected:
        return AppIcons.statusRejected;
    }
  }

  static Color statusColor(PaymentRecordStatus status) {
    switch (status) {
      case PaymentRecordStatus.pending:
        return const Color(0xFFEA580C);
      case PaymentRecordStatus.verified:
        return const Color(0xFF047857);
      case PaymentRecordStatus.rejected:
        return const Color(0xFFB91C1C);
    }
  }

  static Color statusBackground(PaymentRecordStatus status) {
    switch (status) {
      case PaymentRecordStatus.pending:
        return const Color(0xFFFFF7ED);
      case PaymentRecordStatus.verified:
        return const Color(0xFFECFDF5);
      case PaymentRecordStatus.rejected:
        return const Color(0xFFFEF2F2);
    }
  }

  static String formatCurrency(double amount) {
    if (amount == amount.roundToDouble()) {
      return '₹${amount.toStringAsFixed(0)}';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
