enum ExportFailureCode {
  unauthorized,
  noData,
  missingEvent,
  tenantContext,
  unsupportedFormat,
  generationFailed,
}

class ExportException implements Exception {
  const ExportException(this.code, this.message);

  final ExportFailureCode code;
  final String message;

  factory ExportException.unauthorized() => const ExportException(
        ExportFailureCode.unauthorized,
        'You are not allowed to export this data.',
      );

  factory ExportException.noData() => const ExportException(
        ExportFailureCode.noData,
        'There is no data to export for the current filters.',
      );

  factory ExportException.missingEvent() => const ExportException(
        ExportFailureCode.missingEvent,
        'Open an event before downloading this report.',
      );

  factory ExportException.tenantContext() => const ExportException(
        ExportFailureCode.tenantContext,
        'Export is only available inside an organisation workspace.',
      );

  factory ExportException.unsupportedFormat() => const ExportException(
        ExportFailureCode.unsupportedFormat,
        'That export format is not available yet.',
      );

  factory ExportException.generationFailed([String? detail]) => ExportException(
        ExportFailureCode.generationFailed,
        (detail ?? '').trim().isEmpty ? 'Unable to generate the export.' : detail!.trim(),
      );

  @override
  String toString() => message;
}
