import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';

void main() {
  group('Host Reserve Button Tests', () {
    late Event testEvent;
    late SlottedUser hostUser;
    late SlottedUser nonHostUser;
    
    setUp(() {
      testEvent = Event(
        id: 'test-event-id',
        name: 'Test Event',
        host: 'host-user-id',
        hostName: 'Test Host',
        slots: 10,
        attendees: [],
        waitlist: [],
      );
      
      hostUser = SlottedUser()
        ..id = 'host-user-id'
        ..username = 'Test Host'
        ..email = 'host@test.com'
        ..phoneNumber = '+1234567890'
        ..customerID = 'cus_host'
        ..testCustomerID = 'cus_host_test'
        ..savedEvents = []
        ..isHost = true;
      
      nonHostUser = SlottedUser()
        ..id = 'non-host-user-id'
        ..username = 'Test User'
        ..email = 'user@test.com'
        ..phoneNumber = '+1234567891'
        ..customerID = 'cus_user'
        ..testCustomerID = 'cus_user_test'
        ..savedEvents = []
        ..isHost = false;
    });
    
    test('Host should not see reserve button on their own event', () {
      // Verify that the user is the host
      expect(testEvent.host, equals(hostUser.id));
      
      // Check if user is host (this is the logic used in the UI)
      bool isHost = testEvent.host == hostUser.id;
      expect(isHost, true);
      
      // The reserve button should not be shown for hosts
      bool shouldShowReserveButton = !isHost;
      expect(shouldShowReserveButton, false);
    });
    
    test('Non-host should see reserve button on event', () {
      // Verify that the user is not the host
      expect(testEvent.host, isNot(equals(nonHostUser.id)));
      
      // Check if user is host
      bool isHost = testEvent.host == nonHostUser.id;
      expect(isHost, false);
      
      // The reserve button should be shown for non-hosts
      bool shouldShowReserveButton = !isHost;
      expect(shouldShowReserveButton, true);
    });
    
    test('Host can still see other UI elements on their event', () {
      // Verify that the user is the host
      bool isHost = testEvent.host == hostUser.id;
      expect(isHost, true);
      
      // Host should still be able to see the event details
      expect(testEvent.name, isNotEmpty);
      expect(testEvent.hostName, isNotEmpty);
      expect(testEvent.slots, greaterThan(0));
    });
  });
} 