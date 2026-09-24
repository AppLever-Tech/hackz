/// Central paths for approved Hackz brand raster assets.
///
/// Exports must be RGBA with transparency. RGB-on-black files are keyed at
/// runtime ([HackzBrandImageKey]) and can be fixed in-repo via
/// `dart run tool/process_brand_assets.dart`.
abstract final class HackzBrandAssets {
  HackzBrandAssets._();

  static const String _root = 'assets/branding';

  /// Full brand: symbol + Hackz + Solve.Research.Kickstart.
  static const String primaryLogo = '$_root/hackz_primary_logo.png';

  /// Symbol + Hackz wordmark (launcher / splash; no tagline).
  static const String launcherLogo = '$_root/hackz_launcher_logo.png';

  /// Compact symbol only (favicon, nav rail, avatars).
  static const String symbol = '$_root/hackz_symbol.png';

  /// Loading artwork (H + orbit; single raster).
  static const String loadingSymbol = '$_root/hackz_loading_symbol.png';

  /// Rotating orbit + dot (paired with [loadingHLayer]).
  static const String loadingOrbitLayer = '$_root/hackz_loading_orbit.png';

  /// Stationary H for loading animation.
  static const String loadingHLayer = '$_root/hackz_loading_h.png';
}
