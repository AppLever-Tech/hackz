import 'package:flutter/material.dart';

import 'hkz_loading_controller.dart';
import 'hkz_loading_theme.dart';
import 'hkz_progress_indicator.dart';

/// Compact elevated loading panel shown inside the overlay.
class HkzLoadingCard extends StatelessWidget {
  const HkzLoadingCard({
    super.key,
    required this.controller,
  });

  final HkzLoadingController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (controller.status) {
      case HkzLoadingStatus.success:
        return _StatusBody(
          key: const ValueKey<String>('success'),
          icon: Icons.check_circle_rounded,
          iconColor: HkzLoadingTheme.successColor,
          title: controller.title,
          message: controller.message ?? 'Done',
        );
      case HkzLoadingStatus.error:
        return _StatusBody(
          key: const ValueKey<String>('error'),
          icon: Icons.error_outline_rounded,
          iconColor: HkzLoadingTheme.errorColor,
          title: 'Something went wrong',
          message: controller.errorMessage ?? 'Please try again.',
          action: controller.onRetry == null
              ? null
              : TextButton(
                  onPressed: controller.onRetry,
                  child: const Text('Retry'),
                ),
        );
      case HkzLoadingStatus.loading:
        return _LoadingBody(
          key: const ValueKey<String>('loading'),
          title: controller.title,
          message: controller.message,
          progress: controller.progress,
        );
    }
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({
    super.key,
    required this.title,
    this.message,
    this.progress,
  });

  final String title;
  final String? message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HkzLoadingTheme.cardWidth(context),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: HkzLoadingTheme.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const HkzProgressIndicator(),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: HkzLoadingTheme.titleStyle(context),
          ),
          if (message != null && message!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: HkzLoadingTheme.messageStyle,
            ),
          ],
          if (progress != null) ...<Widget>[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6A38FF)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HkzLoadingTheme.cardWidth(context),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: HkzLoadingTheme.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: HkzLoadingTheme.titleStyle(context),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: HkzLoadingTheme.messageStyle,
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: 10),
            action!,
          ],
        ],
      ),
    );
  }
}
