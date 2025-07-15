// App Store configuration
class AppStoreConfig {
  // App information
  static const String appName = 'Open Slot';
  static const String bundleId = 'com.openslot.app';
  static const String sku = 'openslot2023';
  static const String version = '1.0.95';
  static const int buildNumber = 129;

  // App Store metadata
  static const String description = 'Open Slot - Find and join local events happening near you! Discover, reserve, and join events in your city.';
  static const String keywords = 'events,local,comedy,music,poetry,dj,performances,shows,open mic,entertainment,tickets,live,nearby';
  static const String supportUrl = 'https://www.openslotapp.com/support';
  static const String privacyUrl = 'https://www.openslotapp.com/privacy';

  // App Store requirements
  static const String ageRating = '4+';
  static const String price = 'Free';
  static const List<String> territories = ['US', 'CA', 'GB', 'AU'];

  // App Store review information
  static const String reviewNotes = 'This app allows users to find and reserve spots at local events. The app uses location services to display nearby events on a map. Key features: event discovery, reservation system, real-time updates, authentication, and payment processing.';

  // Screenshot requirements
  static const List<String> requiredScreenshots = [
    '6.5 inch display (1284 x 2778 px)',
    '5.5 inch display (1242 x 2208 px)',
    '12.9 inch iPad Pro (2048 x 2732 px)',
  ];
}
