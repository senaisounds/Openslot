import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum EventType {
  mic,
  deck,
}

class Event {
  String address = '';
  List<String> attendees = [];
  DateTime date = DateTime.fromMillisecondsSinceEpoch(0);
  bool ended = false;
  String host = '';
  String hostName = '';
  String id = '';
  bool live = false;
  LatLng location = const LatLng(0, 0);
  String name = '';
  String? performer;
  DateTime? performerStart;
  double price = 0;
  Map<String, DateTime> reservationTimestamps = {};
  String rules = '';
  bool signupOnLocation = false;
  int slots = 0;
  int timeLimit = 0;
  EventType type = EventType.mic;
  List<String> waitlist = [];

  int get openSlots {
    return max(0, slots - attendees.length);
  }

  static Event fromDocument(DocumentSnapshot document) {
    if (document.data() == null) {
      return Event();
    }
    final docData = document.data()! as Map<String, dynamic>;

    final event = Event();
    if (docData['address'] != null) {
      event.address = docData['address'];
    }
    if (docData['attendees'] != null) {
      event.attendees = List<String>.from(docData['attendees']);
    }
    if (docData['date'] != null) {
      event.date = (docData['date'] as Timestamp).toDate();
    }
    if (docData['ended'] != null) {
      event.ended = docData['ended'];
    }
    if (docData['host'] != null) {
      event.host = docData['host'];
    }
    if (docData['hostName'] != null) {
      event.hostName = docData['hostName'];
    }
    event.id = docData['id'] ?? document.id;
    if (docData['live'] != null) {
      event.live = docData['live'];
    }
    if (docData['location'] != null) {
      final location = docData['location'] as GeoPoint;
      event.location = LatLng(location.latitude, location.longitude);
    }
    if (docData['name'] != null) {
      event.name = docData['name'];
    }
    if (docData['performer'] != null) {
      event.performer = docData['performer'];
    }
    if (docData['performerStart'] != null) {
      event.performerStart = (docData['performerStart'] as Timestamp).toDate();
    }
    if (docData['price'] != null) {
      event.price = docData['price'] * 1.0;
    }
    if (docData['reservationTimestamps'] != null) {
      Map<String, Timestamp> reservationTimestamps =
          Map<String, Timestamp>.from(docData['reservationTimestamps']);

      event.reservationTimestamps = reservationTimestamps.map((key, value) {
        return MapEntry(key, value.toDate());
      });
    }
    if (docData['rules'] != null) {
      event.rules = docData['rules'];
    }
    if (docData['signupOnLocation'] != null) {
      event.signupOnLocation = docData['signupOnLocation'];
    }
    if (docData['slots'] != null) {
      event.slots = docData['slots'];
    }
    if (docData['timeLimit'] != null) {
      event.timeLimit = docData['timeLimit'];
    }
    if (docData['type'] != null) {
      event.type = docData['type'] == 'DECK' ? EventType.deck : EventType.mic;
    }
    if (docData['waitlist'] != null) {
      event.waitlist = List<String>.from(docData['waitlist']);
    }

    return event;
  }

  static Map<String, dynamic> toDocument(
    Event event, {
    bool deletingAttendees = false,
    bool deletingWaitlist = false,
  }) {
    final docData = <String, dynamic>{};

    docData['address'] = event.address;
    docData['attendees'] = deletingAttendees
        ? event.attendees
        : FieldValue.arrayUnion(event.attendees);
    docData['date'] = event.date;
    docData['ended'] = event.ended;
    docData['host'] = event.host;
    docData['hostName'] = event.hostName;
    docData['id'] = event.id;
    docData['live'] = event.live;
    docData['location'] =
        GeoPoint(event.location.latitude, event.location.longitude);
    docData['name'] = event.name;
    docData['performer'] = event.performer;
    docData['performerStart'] = event.performerStart;
    docData['price'] = event.price;
    docData['reservationTimestamps'] =
        event.reservationTimestamps.map((key, value) {
      return MapEntry(key, Timestamp.fromDate(value));
    });
    docData['rules'] = event.rules;
    docData['signupOnLocation'] = event.signupOnLocation;
    docData['slots'] = event.slots;
    docData['timeLimit'] = event.timeLimit;
    docData['type'] = event.type.name.toUpperCase();
    docData['waitlist'] = deletingWaitlist
        ? event.waitlist
        : FieldValue.arrayUnion(event.waitlist);

    return docData;
  }
}
