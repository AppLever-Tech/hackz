/// Firestore document ids under `hkzAppMetadata`.
abstract final class AppMetadataKeys {
  AppMetadataKeys._();

  static const String about = 'about';
  static const String projectTeam = 'projectTeam';
  static const String privacyPolicy = 'privacyPolicy';
  static const String terms = 'terms';
  static const String appInfo = 'appInfo';

  static const List<String> all = <String>[
    about,
    projectTeam,
    privacyPolicy,
    terms,
    appInfo,
  ];
}

/// Payload type discriminator stored on each metadata document.
enum AppMetadataType {
  text('text'),
  projectTeam('projectTeam'),
  appInfo('appInfo');

  const AppMetadataType(this.value);
  final String value;

  static AppMetadataType fromRaw(String raw) {
    return switch (raw.trim()) {
      'projectTeam' => AppMetadataType.projectTeam,
      'appInfo' => AppMetadataType.appInfo,
      _ => AppMetadataType.text,
    };
  }
}
