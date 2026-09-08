import 'package:flutter/material.dart';

import '../../exports/models/export_format.dart';
import '../../exports/models/export_request.dart';
import '../../exports/services/export_data_provider.dart';

/// Downloadable event document (certificates, reports) shared by Ideathon/Hackathon.
class EventReportItem {
  const EventReportItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.available,
    this.unavailableReason = '',
    this.provider,
    this.requestFor,
    this.actionLabel = 'Download',
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool available;
  final String unavailableReason;
  final ExportDataProvider? provider;
  final ExportRequest Function(ExportFormat format)? requestFor;
  final String actionLabel;
}
