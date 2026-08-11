import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/utils/logger.dart';

/// Loads scraped/discovered open mics for the feed.
///
/// Uses a bundled snapshot so the app can show Comediq / Eventbrite / Do512
/// listings before Cloud Function scrapes are deployed to Firestore.
class OpenMicDiscoveryService {
  OpenMicDiscoveryService._();
  static final OpenMicDiscoveryService instance = OpenMicDiscoveryService._();

  static const String snapshotAsset = 'assets/discovery/open_mics_snapshot.json';

  List<Event>? _cached;

  Future<List<Event>> loadDiscoveredOpenMics({bool forceReload = false}) async {
    if (!forceReload && _cached != null) return _cached!;

    try {
      final raw = await rootBundle.loadString(snapshotAsset);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final rows = (decoded['events'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((row) => Event.fromDiscoveryMap(Map<String, dynamic>.from(row)))
          .where((event) => event.id.isNotEmpty && event.name.isNotEmpty)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      _cached = rows;
      Logger.d(
        'Loaded ${rows.length} discovered open mics from snapshot',
        tag: 'Discovery',
      );
      return rows;
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to load discovered open mics: $e',
        tag: 'Discovery',
        error: e,
        stackTrace: stackTrace,
      );
      _cached = const [];
      return _cached!;
    }
  }

  /// Merge Firestore-hosted events with discovered listings (Firestore wins on id).
  List<Event> mergeWithFirestoreEvents(
    List<Event> firestoreEvents,
    List<Event> discoveredEvents,
  ) {
    final byId = <String, Event>{};
    final byExternalUrl = <String, Event>{};

    for (final event in firestoreEvents) {
      byId[event.id] = event;
      final external = event.externalUrl?.trim() ?? '';
      if (external.isNotEmpty) byExternalUrl[external] = event;
    }

    for (final discovered in discoveredEvents) {
      if (byId.containsKey(discovered.id)) continue;
      final external = discovered.externalUrl?.trim() ?? '';
      if (external.isNotEmpty && byExternalUrl.containsKey(external)) continue;
      byId[discovered.id] = discovered;
    }

    return byId.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }
}
