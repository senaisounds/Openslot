import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType {
  mic,
  deck,
}

class Event {
  double dateTime = 0;
  String venueName = '';
  String address = '';
  int totalSpots = 0;
  List<String> attendees = [];
  List<String> waitlist = [];
  Map<String, double> reserveTimes = {};
  String host = '';
  String hostName = '';
  String id = '';
  EventType type = EventType.mic;
  bool requiresPhysicalSignup = false;
  int timeLimit = 0;
  String performer = '';
  double performerStart = 0;
  String rules = '';
  bool live = false;
  bool ended = false;
  double price = 0;

  int get openSpots {
    return max(0, totalSpots - attendees.length);
  }

  static Event fromDocument(QueryDocumentSnapshot document) {
    if (document.data() == null) {
      return Event();
    }
    final docData = document.data()! as Map<String, dynamic>;

    final event = Event();
    event.dateTime = (docData['dateTime'] ?? 0.0) is int
        ? (docData['dateTime'] ?? 0.0).toDouble()
        : (docData['dateTime'] ?? 0.0);
    event.venueName = docData['venueName'] ?? '';
    event.address = docData['address'] ?? '';
    event.totalSpots = docData['totalSpots'] ?? 0;
    event.reserveTimes = (docData['reserveTimes'] ?? {}).cast<String, double>();
    event.attendees = (docData['attendees'] ?? []).sort((p0, p1) {
          if (event.reserveTimes[p0] == null) {
            return -1;
          } else if (event.reserveTimes[p1] == null) {
            return 1;
          } else {
            final reserve0 = event.reserveTimes[p0]! is int
                ? event.reserveTimes[p0]!.toDouble()
                : event.reserveTimes[p0]!;
            final reserve1 = event.reserveTimes[p1]! is int
                ? event.reserveTimes[p1]!.toDouble()
                : event.reserveTimes[p1]!;
            return reserve0.compareTo(reserve1);
          }
        }) ??
        [];
    event.waitlist = (docData['waitlist'] ?? []).sort((p0, p1) {
          if (event.reserveTimes[p0] == null) {
            return -1;
          } else if (event.reserveTimes[p1] == null) {
            return 1;
          } else {
            final reserve0 = event.reserveTimes[p0]! is int
                ? event.reserveTimes[p0]!.toDouble()
                : event.reserveTimes[p0]!;
            final reserve1 = event.reserveTimes[p1]! is int
                ? event.reserveTimes[p1]!.toDouble()
                : event.reserveTimes[p1]!;
            return reserve0.compareTo(reserve1);
          }
        }) ??
        [];
    event.host = docData['host'] ?? '';
    event.hostName = docData['hostName'] ?? '';
    event.id = docData['id'] ?? '';
    event.type =
        (docData['type'] ?? 'MIC') == 'DECK' ? EventType.deck : EventType.mic;
    event.requiresPhysicalSignup = docData['requiresPhysicalSignup'] ?? false;
    event.timeLimit = docData['timeLimit'] ?? 0;
    event.performer = docData['performer'] ?? '';
    event.performerStart = (docData['performerStart'] ?? 0.0) is int
        ? (docData['performerStart'] ?? 0.0).toDouble()
        : (docData['performerStart'] ?? 0.0);
    event.rules = docData['rules'] ?? '';
    event.live = docData['live'] ?? false;
    event.ended = docData['ended'] ?? false;
    event.price = (docData['price'] ?? 0.0) is int
        ? (docData['price'] ?? 0.0).toDouble()
        : (docData['price'] ?? 0.0);

    return event;
  }
}
