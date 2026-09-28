import 'package:flutter/foundation.dart';

enum HkzLoadingStatus { loading, success, error }

/// Mutable state for an active loading overlay.
class HkzLoadingController extends ChangeNotifier {
  HkzLoadingController({
    required this.title,
    this.message,
    this.status = HkzLoadingStatus.loading,
    this.progress,
    this.errorMessage,
    this.onRetry,
  });

  String title;
  String? message;
  HkzLoadingStatus status;
  double? progress;
  String? errorMessage;
  VoidCallback? onRetry;

  void update({
    String? title,
    String? message,
    HkzLoadingStatus? status,
    double? progress,
    bool clearProgress = false,
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    if (title != null) this.title = title;
    if (message != null) this.message = message;
    if (status != null) this.status = status;
    if (clearProgress) {
      this.progress = null;
    } else if (progress != null) {
      this.progress = progress;
    }
    if (errorMessage != null) this.errorMessage = errorMessage;
    if (onRetry != null) this.onRetry = onRetry;
    notifyListeners();
  }

  void setLoading({String? title, String? message, double? progress}) {
    update(
      title: title,
      message: message,
      status: HkzLoadingStatus.loading,
      progress: progress,
      errorMessage: null,
    );
  }

  void setSuccess({String? message}) {
    update(
      status: HkzLoadingStatus.success,
      message: message ?? 'Complete',
      errorMessage: null,
    );
  }

  void setError(String message, {VoidCallback? onRetry}) {
    update(
      status: HkzLoadingStatus.error,
      errorMessage: message,
      onRetry: onRetry,
    );
  }
}
