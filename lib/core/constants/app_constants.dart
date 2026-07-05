/// Application-wide constants.
abstract final class AppConstants {
  static const String appName = 'DM Auto OS';
  static const String appTagline =
      'Vehicle Rental, Trading & Service Management';

  static const String defaultLocale = 'fr_CM';

  static const Duration sessionRefreshInterval = Duration(minutes: 55);
  static const Duration networkTimeout = Duration(seconds: 30);

  static const int itemsPerPage = 20;
}
