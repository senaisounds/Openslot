import 'package:flutter/cupertino.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/utils/logger.dart';

class SimpleOfflineCache {
  static SimpleOfflineCache? _instance;
  static SimpleOfflineCache get instance => _instance ??= SimpleOfflineCache._();
  
  SimpleOfflineCache._();
  
  List<Event>? _cachedEvents;
  DateTime? _lastUpdate;
  static const Duration _cacheExpiry = Duration(hours: 6);

  void cacheEvents(List<Event> events) {
    try {
      _cachedEvents = List.from(events);
      _lastUpdate = DateTime.now();
      Logger.d('Cached ${events.length} events for offline access');
    } catch (e) {
      Logger.e('Failed to cache events: $e', error: e);
    }
  }

  List<Event> getCachedEvents() {
    if (_cachedEvents != null && _isCacheValid()) {
      Logger.d('Loaded ${_cachedEvents!.length} events from offline cache');
      return List.from(_cachedEvents!);
    }
    return [];
  }

  bool _isCacheValid() {
    if (_lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!) < _cacheExpiry;
  }

  bool hasCachedEvents() {
    return _cachedEvents != null && _cachedEvents!.isNotEmpty && _isCacheValid();
  }

  void clearCache() {
    _cachedEvents = null;
    _lastUpdate = null;
    Logger.d('Offline event cache cleared');
  }

  Event? getCachedEvent(String eventId) {
    if (_cachedEvents == null) return null;
    try {
      return _cachedEvents!.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }

  Duration? get cacheAge {
    if (_lastUpdate == null) return null;
    return DateTime.now().difference(_lastUpdate!);
  }

  bool get isCacheExpired => !_isCacheValid();
}

class OfflineIndicator extends StatelessWidget {
  final bool isOffline;
  
  const OfflineIndicator({
    super.key,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: CupertinoColors.systemOrange,
      child: const SafeArea(
        bottom: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.wifi_slash,
              color: CupertinoColors.white,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'You\'re offline. Showing cached events.',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 