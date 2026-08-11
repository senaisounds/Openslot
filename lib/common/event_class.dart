import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum EventType {
  mic,
  deck,
}

class Event {
  String id;
  String name;
  String host;
  String description;
  String rules;
  LatLng location;
  DateTime date;
  bool live;
  bool ended;
  String? performer;
  DateTime? performerStart;
  int timeLimit;
  List<String> attendees;
  Map<String, DateTime> reservationTimestamps;
  Set<String> checkedPerformers;
  String address;
  String category;
  String hostName;
  String? upNext;
  double price;
  bool signupOnLocation;
  int slots;
  EventType type;
  List<String> waitlist;
  bool isPrivate;
  String? password;
  String coverUrl;
  bool isFeatured;
  int capacity;
  List<String> checkedPerformersList;
  /// True when this listing was discovered by the web scraper.
  bool isScraped;
  /// Origin platform for scraped listings (e.g. eventbrite).
  String source;
  /// Canonical public URL for scraped/external listings.
  String? externalUrl;
  /// City label used for discovery / location filters.
  String city;

  Event({
    required this.id,
    this.name = '',
    this.host = '',
    this.description = '',
    this.rules = '',
    LatLng? location,
    DateTime? date,
    this.live = false,
    this.ended = false,
    this.performer,
    this.performerStart,
    this.timeLimit = 0,
    List<String>? attendees,
    Map<String, DateTime>? reservationTimestamps,
    Set<String>? checkedPerformers,
    this.address = '',
    this.category = 'other',
    this.hostName = '',
    this.upNext,
    this.price = 0,
    this.signupOnLocation = false,
    this.slots = 0,
    this.type = EventType.mic,
    List<String>? waitlist,
    this.isPrivate = false,
    this.password,
    this.coverUrl = '',
    this.isFeatured = false,
    this.capacity = 0,
    this.checkedPerformersList = const [],
    this.isScraped = false,
    this.source = 'openslot',
    this.externalUrl,
    this.city = '',
  }) : 
    location = location ?? const LatLng(0, 0),
    date = date ?? DateTime.now(),
    attendees = attendees ?? [],
    reservationTimestamps = reservationTimestamps ?? {},
    checkedPerformers = checkedPerformers ?? const {},
    waitlist = waitlist ?? const [];

  factory Event.empty() {
    return Event(id: '');
  }

  factory Event.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    LatLng parseLocation(Map<String, dynamic> data) {
      if (data['location'] is GeoPoint) {
        final geoPoint = data['location'] as GeoPoint;
        return LatLng(geoPoint.latitude, geoPoint.longitude);
      }
      return const LatLng(0, 0);
    }

    return Event(
      id: doc.id,
      name: data['name'] as String? ?? '',
      host: data['host'] as String? ?? '',
      description: data['description'] as String? ?? '',
      rules: data['rules'] as String? ?? '',
      location: parseLocation(data),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      live: data['live'] as bool? ?? false,
      ended: data['ended'] as bool? ?? false,
      performer: data['performer'] as String?,
      performerStart: (data['performerStart'] as Timestamp?)?.toDate(),
      timeLimit: data['timeLimit'] as int? ?? 0,
      attendees: List<String>.from(data['attendees'] as List? ?? []),
      reservationTimestamps: (data['reservationTimestamps'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      ),
      checkedPerformers: Set<String>.from(data['checkedPerformers'] as List? ?? []),
      address: data['address'] as String? ?? '',
      category: data['category'] as String? ?? 'other',
      hostName: data['hostName'] as String? ?? '',
      upNext: data['upNext'] as String?,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      signupOnLocation: data['signupOnLocation'] as bool? ?? false,
      slots: data['slots'] as int? ?? 0,
      type: data['type'] == 'deck' ? EventType.deck : EventType.mic,
      waitlist: List<String>.from(data['waitlist'] as List? ?? []),
      isPrivate: data['isPrivate'] as bool? ?? false,
      password: data['password'] as String?,
      coverUrl: data['coverUrl'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      checkedPerformersList: List<String>.from(data['checkedPerformers'] as List? ?? []),
      isScraped: data['isScraped'] as bool? ?? false,
      source: data['source'] as String? ?? 'openslot',
      externalUrl: data['externalUrl'] as String?,
      city: data['city'] as String? ?? '',
    );
  }

  /// Build an event from the bundled web-discovery snapshot JSON.
  factory Event.fromDiscoveryMap(Map<String, dynamic> data) {
    return Event(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      host: 'openslot_web_scraper',
      description: data['description'] as String? ?? '',
      rules: data['rules'] as String? ??
          'Discovered from the web. Sign up on the original listing.',
      location: LatLng(
        (data['lat'] as num?)?.toDouble() ?? 0,
        (data['lng'] as num?)?.toDouble() ?? 0,
      ),
      date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
      live: data['live'] as bool? ?? false,
      ended: data['ended'] as bool? ?? false,
      address: data['address'] as String? ?? '',
      category: data['category'] as String? ?? 'comedy',
      hostName: data['hostName'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      signupOnLocation: data['signupOnLocation'] as bool? ?? true,
      slots: (data['slots'] as num?)?.toInt() ?? 0,
      type: data['type'] == 'deck' ? EventType.deck : EventType.mic,
      coverUrl: data['coverUrl'] as String? ?? '',
      isScraped: data['isScraped'] as bool? ?? true,
      source: data['source'] as String? ?? 'web',
      externalUrl: data['externalUrl'] as String?,
      city: data['city'] as String? ?? '',
    );
  }

  /// Whether this event should open an external listing instead of in-app reserve.
  bool get isExternalListing =>
      isScraped || (externalUrl != null && externalUrl!.trim().isNotEmpty);

  Map<String, dynamic> toDocument() {
    return {
      'name': name,
      'host': host,
      'description': description,
      'rules': rules,
      'location': GeoPoint(location.latitude, location.longitude),
      'date': Timestamp.fromDate(date),
      'live': live,
      'ended': ended,
      'performer': performer,
      'performerStart': performerStart != null ? Timestamp.fromDate(performerStart!) : null,
      'timeLimit': timeLimit,
      'attendees': attendees,
      'reservationTimestamps': reservationTimestamps.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'checkedPerformers': checkedPerformers.toList(),
      'address': address,
      'category': category,
      'hostName': hostName,
      'upNext': upNext,
      'price': price,
      'signupOnLocation': signupOnLocation,
      'slots': slots,
      'type': type == EventType.deck ? 'deck' : 'mic',
      'waitlist': waitlist,
      'isPrivate': isPrivate,
      'password': password,
      'coverUrl': coverUrl,
      'isFeatured': isFeatured,
      'capacity': capacity,
      'checkedPerformersList': checkedPerformersList,
      'isScraped': isScraped,
      'source': source,
      'externalUrl': externalUrl,
      'city': city,
    };
  }

  int get openSlots {
    if (slots <= 0) return 0;
    return max(0, slots - attendees.length);
  }

  bool get isHappeningNow {
    final now = DateTime.now();
    return !ended && date.isBefore(now) && live;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return !ended && date.isAfter(now);
  }

  bool get isFull {
    return openSlots <= 0;
  }

  String get formattedPrice {
    if (price <= 0) return 'Free';
    return '\$${price.toStringAsFixed(2)}';
  }
  
  int getWaitlistPosition(String userId) {
    final index = waitlist.indexOf(userId);
    if (index == -1) return 0;
    return index + 1;
  }
  
  int get waitlistCount {
    return waitlist.length;
  }
}
