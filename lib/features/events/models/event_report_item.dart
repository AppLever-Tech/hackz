import 'package:flutter/material.dart';

/// Downloadable event document (certificates, reports) shared by Ideathon/Hackathon.
class EventReportItem {
  const EventReportItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.available,
    this.unavailableReason = '',
    this.onDownload,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool available;
  final String unavailableReason;
  final VoidCallback? onDownload;
}
