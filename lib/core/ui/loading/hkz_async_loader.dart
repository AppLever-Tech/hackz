import 'package:flutter/material.dart';

import 'hkz_loading_overlay.dart';

/// Runs an async task with the standard Hackz loading overlay.
abstract final class HkzAsyncLoader {
  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function() task,
    required String title,
    String? message,
    String? successMessage,
    Duration successHold = const Duration(milliseconds: 650),
    bool hideOnError = true,
    void Function(String error)? onError,
  }) async {
    HkzLoadingOverlay.show(
      context,
      title: title,
      message: message,
    );
    try {
      final T result = await task();
      await HkzLoadingOverlay.completeSuccess(
        message: successMessage,
        hold: successHold,
      );
      return result;
    } catch (e) {
      final String errorText = _formatError(e);
      onError?.call(errorText);
      if (hideOnError) {
        HkzLoadingOverlay.hide();
      } else {
        HkzLoadingOverlay.showError(errorText);
      }
      rethrow;
    }
  }

  /// Updates overlay copy while a long task is running (no [BuildContext] needed).
  static void update({
    String? title,
    String? message,
    double? progress,
  }) {
    HkzLoadingOverlay.controller?.update(
      title: title,
      message: message,
      progress: progress,
    );
  }

  static String _formatError(Object e) {
    final String raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }
}
