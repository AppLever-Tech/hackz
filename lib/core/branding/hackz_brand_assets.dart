/// Central paths for approved Hackz brand raster assets.
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

  /// Optional separate orbit/dot layer for [HackzBrandLoadingIndicator] animation.
  /// When null, loading uses a static [loadingSymbol] (no full-image rotation).
  static const String? loadingOrbitLayer = null;

  /// Optional stationary H layer paired with [loadingOrbitLayer].
  static const String? loadingHLayer = null;
}
