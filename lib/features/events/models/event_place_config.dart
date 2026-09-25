import 'package:flutter/material.dart';

import '../../exports/certificate/certificate_type.dart';

/// Official event place (1–3). Internal Firestore fields stay winnerIdeaId / runnerUpIdeaId / thirdPlaceIdeaId.
enum EventPlaceRank {
  first(1),
  second(2),
  third(3);

  const EventPlaceRank(this.rank);
  final int rank;

  static EventPlaceRank? fromRank(int value) {
    for (final EventPlaceRank place in EventPlaceRank.values) {
      if (place.rank == value) return place;
    }
    return null;
  }

  static EventPlaceRank? fromCertificateType(CertificateType type) => switch (type) {
        CertificateType.participation => null,
        CertificateType.winner => EventPlaceRank.first,
        CertificateType.runnerUp => EventPlaceRank.second,
        CertificateType.thirdPlace => EventPlaceRank.third,
      };

  CertificateType get certificateType => switch (this) {
        EventPlaceRank.first => CertificateType.winner,
        EventPlaceRank.second => CertificateType.runnerUp,
        EventPlaceRank.third => CertificateType.thirdPlace,
      };
}

/// User-facing labels, medals, and certificate assets for each place.
abstract final class EventPlacePresentation {
  EventPlacePresentation._();

  static const List<EventPlaceRank> podium = <EventPlaceRank>[
    EventPlaceRank.first,
    EventPlaceRank.second,
    EventPlaceRank.third,
  ];

  static String cardTitle(EventPlaceRank place) => switch (place) {
        EventPlaceRank.first => 'Winner - 1st Place',
        EventPlaceRank.second => '2nd Place',
        EventPlaceRank.third => '3rd Place',
      };

  static String pickerLabel(EventPlaceRank place) => switch (place) {
        EventPlaceRank.first => '1st Place',
        EventPlaceRank.second => '2nd Place',
        EventPlaceRank.third => '3rd Place',
      };

  static String achievementLabel(EventPlaceRank place) => switch (place) {
        EventPlaceRank.first => '1st Place',
        EventPlaceRank.second => '2nd Place',
        EventPlaceRank.third => '3rd Place',
      };

  static String certificateGenerateTitle(CertificateType type) => switch (type) {
        CertificateType.participation => 'Generate Participation Certificates',
        CertificateType.winner => 'Generate 1st Place Certificates',
        CertificateType.runnerUp => 'Generate 2nd Place Certificates',
        CertificateType.thirdPlace => 'Generate 3rd Place Certificates',
      };

  static String certificateReportTitle(EventPlaceRank place) => switch (place) {
        EventPlaceRank.first => '1st Place certificate',
        EventPlaceRank.second => '2nd Place certificate',
        EventPlaceRank.third => '3rd Place certificate',
      };

  static String certificateReportDescription(EventPlaceRank place) => switch (place) {
        EventPlaceRank.first => 'Certificate for the 1st Place team.',
        EventPlaceRank.second => 'Certificate for the 2nd Place team.',
        EventPlaceRank.third => 'Certificate for the 3rd Place team.',
      };

  static String certificateUnavailableReason(EventPlaceRank place) =>
      'Select ${pickerLabel(place).toLowerCase()} on the Winners tab before downloading.';

  static String emptyPlaceMessage(EventPlaceRank place) =>
      '${pickerLabel(place)} not available yet.';

  static IconData medalIcon(EventPlaceRank place) => switch (place) {
        EventPlaceRank.first => Icons.emoji_events_rounded,
        EventPlaceRank.second => Icons.military_tech_rounded,
        EventPlaceRank.third => Icons.workspace_premium_rounded,
      };

  static Color medalAccent(EventPlaceRank place) => switch (place) {
        EventPlaceRank.first => const Color(0xFFC9A227),
        EventPlaceRank.second => const Color(0xFF8B9BB4),
        EventPlaceRank.third => const Color(0xFFCD7F32),
      };

  static String certificateOverlayAsset(EventPlaceRank place) => switch (place) {
        EventPlaceRank.first => 'assets/certificate/overlays/winner_overlay.png',
        EventPlaceRank.second => 'assets/certificate/overlays/second_place_overlay.png',
        EventPlaceRank.third => 'assets/certificate/overlays/third_place_overlay.png',
      };

  /// Legacy runner-up overlay path (fallback if second_place asset missing).
  static const String legacyRunnerUpOverlayAsset = 'assets/certificate/overlays/runner_up_overlay.png';
}
