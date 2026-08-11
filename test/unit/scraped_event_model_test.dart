import 'package:flutter_test/flutter_test.dart';
import 'package:slotted/common/event_class.dart';

void main() {
  group('scraped / external open mic events', () {
    test('isExternalListing is true when isScraped', () {
      final event = Event(id: 'scraped_1', isScraped: true);
      expect(event.isExternalListing, isTrue);
    });

    test('isExternalListing is true when externalUrl is set', () {
      final event = Event(
        id: 'scraped_2',
        externalUrl: 'https://www.eventbrite.com/e/example',
      );
      expect(event.isExternalListing, isTrue);
    });

    test('native events are not external listings', () {
      final event = Event(id: 'native_1', name: 'Hosted Mic');
      expect(event.isExternalListing, isFalse);
      expect(event.source, 'openslot');
    });

    test('toDocument includes discovery fields', () {
      final event = Event(
        id: 'scraped_3',
        name: 'Web Mic',
        isScraped: true,
        source: 'eventbrite',
        externalUrl: 'https://www.eventbrite.com/e/web-mic',
      );
      final doc = event.toDocument();
      expect(doc['isScraped'], isTrue);
      expect(doc['source'], 'eventbrite');
      expect(doc['externalUrl'], 'https://www.eventbrite.com/e/web-mic');
    });
  });
}
