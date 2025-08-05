import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/utils/validation_service.dart';
import 'package:slotted/common/event_class.dart' as event_class;
import 'package:slotted/common/slotted_user.dart';

void main() {
  group('Content Filtering Tests', () {
    test('Profanity filtering works', () {
      final validationService = ValidationService.instance;
      
      // Test profanity in event description
      final event = event_class.Event(
        id: 'test-event',
        name: 'Test Event',
        description: 'This event is fucking awesome!', // Contains profanity
        address: '123 Test St',
        date: DateTime.now(),
        category: 'Test',
        host: 'test-user',
        hostName: 'Test User',
        capacity: 10,
        attendees: [],
        waitlist: [],
        rules: '',
        isPrivate: false,
        password: '',
        price: 0,
        isFeatured: false,
      );
      
      final errors = validationService.validateEvent(event);
      expect(errors['description'], isNotNull);
      expect(errors['description']!.contains('inappropriate'), isTrue);
    });
    
    test('Hate speech filtering works', () {
      final validationService = ValidationService.instance;
      
      // Test hate speech in user bio
      final user = SlottedUser()
        ..id = 'test-user'
        ..username = 'testuser'
        ..email = 'test@example.com'
        ..bio = 'All black people should die' // Contains hate speech
        ..instagram = ''
        ..twitter = ''
        ..savedEvents = []
        ..blockedUsers = []
        ..awards = [];
      
      final errors = validationService.validateUser(user);
      expect(errors['bio'], isNotNull);
      expect(errors['bio']!.contains('hate speech'), isTrue);
    });
    
    test('Inappropriate content filtering works', () {
      final validationService = ValidationService.instance;
      
      // Test inappropriate content in event rules
      final event = event_class.Event(
        id: 'test-event',
        name: 'Test Event',
        description: 'A fun event',
        address: '123 Test St',
        date: DateTime.now(),
        category: 'Test',
        host: 'test-user',
        hostName: 'Test User',
        capacity: 10,
        attendees: [],
        waitlist: [],
        rules: 'Come get drunk and high!', // Contains inappropriate content
        isPrivate: false,
        password: '',
        price: 0,
        isFeatured: false,
      );
      
      final errors = validationService.validateEvent(event);
      expect(errors['rules'], isNotNull);
      expect(errors['rules']!.contains('inappropriate'), isTrue);
    });
    
    test('Spam filtering works', () {
      final validationService = ValidationService.instance;
      
      // Test spam content in event description
      final event = event_class.Event(
        id: 'test-event',
        name: 'Test Event',
        description: 'Buy now! Make money fast! Click here!', // Contains spam
        address: '123 Test St',
        date: DateTime.now(),
        category: 'Test',
        host: 'test-user',
        hostName: 'Test User',
        capacity: 10,
        attendees: [],
        waitlist: [],
        rules: '',
        isPrivate: false,
        password: '',
        price: 0,
        isFeatured: false,
      );
      
      final errors = validationService.validateEvent(event);
      expect(errors['description'], isNotNull);
      expect(errors['description']!.contains('spam'), isTrue);
    });
    
    test('Clean content passes validation', () {
      final validationService = ValidationService.instance;
      
      // Test clean content
      final event = event_class.Event(
        id: 'test-event',
        name: 'Fun Music Night',
        description: 'Join us for a great evening of live music and entertainment!',
        address: '123 Music St',
        date: DateTime.now(),
        category: 'Music',
        host: 'test-user',
        hostName: 'Test User',
        capacity: 10,
        attendees: [],
        waitlist: [],
        rules: 'Please be respectful and have fun!',
        isPrivate: false,
        password: '',
        price: 0,
        isFeatured: false,
      );
      
      final errors = validationService.validateEvent(event);
      expect(errors.isEmpty, isTrue);
    });
  });
} 