import 'package:flutter/material.dart';

import '../enums/app_alert_type.dart';
import '../models/app_alert_action.dart';
import '../widgets/app_alert_dialog.dart';

abstract final class FeedbackService {
  static Future<void> showSuccess(
    BuildContext context, {
    String title = 'Success',
    required String message,
    String okLabel = 'OK',
  }) {
    return _showInfoLike(
      context,
      type: AppAlertType.success,
      title: title,
      message: message,
      okLabel: okLabel,
    );
  }

  static Future<void> showError(
    BuildContext context, {
    String title = 'Something went wrong',
    required String message,
    String okLabel = 'OK',
  }) {
    return _showInfoLike(
      context,
      type: AppAlertType.error,
      title: title,
      message: message,
      okLabel: okLabel,
    );
  }

  static Future<void> showWarning(
    BuildContext context, {
    String title = 'Warning',
    required String message,
    String okLabel = 'OK',
  }) {
    return _showInfoLike(
      context,
      type: AppAlertType.warning,
      title: title,
      message: message,
      okLabel: okLabel,
    );
  }

  static Future<void> showInfo(
    BuildContext context, {
    String title = 'Info',
    required String message,
    String okLabel = 'OK',
  }) {
    return _showInfoLike(
      context,
      type: AppAlertType.info,
      title: title,
      message: message,
      okLabel: okLabel,
    );
  }

  static Future<bool> showConfirmation(
    BuildContext context, {
    String title = 'Confirm',
    required String message,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Confirm',
    bool dangerConfirm = false,
    bool barrierDismissible = true,
  }) async {
    final bool? result = await _showDialog<bool>(
      context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return AppAlertDialog(
          type: AppAlertType.confirmation,
          title: title,
          message: message,
          actions: <AppAlertAction>[
            AppAlertAction(
              label: cancelLabel,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              icon: Icons.close_rounded,
            ),
            AppAlertAction(
              label: confirmLabel,
              primary: true,
              danger: dangerConfirm,
              icon: dangerConfirm ? Icons.delete_outline_rounded : Icons.check_rounded,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  static Future<void> _showInfoLike(
    BuildContext context, {
    required AppAlertType type,
    required String title,
    required String message,
    required String okLabel,
  }) {
    return _showDialog<void>(
      context,
      builder: (BuildContext dialogContext) {
        return AppAlertDialog(
          type: type,
          title: title,
          message: message,
          actions: <AppAlertAction>[
            AppAlertAction(
              label: okLabel,
              primary: true,
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  static Future<T?> _showDialog<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: 'feedback-alert',
      barrierDismissible: barrierDismissible,
      barrierColor: const Color(0x6610143B),
      transitionDuration: AppAlertDialog.enterDuration,
      pageBuilder: (BuildContext dialogContext, Animation<double> __, Animation<double> ___) {
        return builder(dialogContext);
      },
      transitionBuilder: (BuildContext _, Animation<double> animation, Animation<double> __, Widget child) {
        final Animation<double> fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final Animation<double> scale = Tween<double>(begin: 0.96, end: 1.0).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }
}

