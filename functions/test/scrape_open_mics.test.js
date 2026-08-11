/**
 * Lightweight parser tests for open mic discovery (no Firebase required).
 * Run: node test/scrape_open_mics.test.js
 */
const assert = require('assert');
const path = require('path');

let parseEventbriteJsonLd;
let extractJsonLdPayloads;
let scrapedEventId;
let inferCategory;
let parseComediqMics;
let nextWeeklyOccurrences;
let parseClockTime;
let parseDo512Events;
let normalizeComediqCity;

try {
  ({
    parseEventbriteJsonLd,
    extractJsonLdPayloads,
    scrapedEventId,
    inferCategory,
    parseComediqMics,
    nextWeeklyOccurrences,
    parseClockTime,
    parseDo512Events,
    normalizeComediqCity,
  } = require('../lib/scrape_open_mics'));
} catch (error) {
  console.error('Build functions first: cd functions && npm run build');
  throw error;
}

const sampleHtml = `
<html><head>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "ItemList",
  "itemListElement": [
    {
      "position": 1,
      "@type": "ListItem",
      "item": {
        "@type": "Event",
        "name": "Downtown Comedy Open Mic",
        "description": "Stand-up comedy open mic night",
        "url": "https://www.eventbrite.com/e/downtown-comedy-open-mic-tickets-123",
        "startDate": "2030-01-15T20:00:00-05:00",
        "image": "https://example.com/cover.jpg",
        "location": {
          "@type": "Place",
          "name": "Laugh Factory",
          "address": {
            "@type": "PostalAddress",
            "streetAddress": "100 Main St",
            "addressLocality": "New York",
            "addressRegion": "NY",
            "postalCode": "10001"
          },
          "geo": {
            "@type": "GeoCoordinates",
            "latitude": "40.7128",
            "longitude": "-74.0060"
          }
        }
      }
    },
    {
      "position": 2,
      "@type": "ListItem",
      "item": {
        "@type": "Event",
        "name": "Missing Date Mic",
        "url": "https://www.eventbrite.com/e/missing-date-tickets-456"
      }
    }
  ]
}
</script>
</head></html>
`;

const payloads = extractJsonLdPayloads(sampleHtml);
assert.strictEqual(payloads.length, 1, 'should extract one JSON-LD block');

const events = parseEventbriteJsonLd(payloads, 'New York');
assert.strictEqual(events.length, 1, 'should skip events without startDate');
assert.strictEqual(events[0].name, 'Downtown Comedy Open Mic');
assert.strictEqual(events[0].venueName, 'Laugh Factory');
assert.strictEqual(events[0].city, 'New York');
assert.strictEqual(events[0].lat, 40.7128);
assert.strictEqual(events[0].lng, -74.006);
assert.strictEqual(events[0].category, 'comedy');
assert.ok(events[0].address.includes('100 Main St'));

const id = scrapedEventId(events[0].url);
assert.ok(id.startsWith('scraped_'));
assert.strictEqual(id, scrapedEventId(events[0].url), 'ids should be stable');

assert.strictEqual(inferCategory('Poetry Slam', ''), 'poetry');
assert.strictEqual(inferCategory('Acoustic Night', 'singer songwriter'), 'music');

// Clock / weekly recurrence
assert.deepStrictEqual(parseClockTime('6:00 PM'), { hours: 18, minutes: 0 });
assert.deepStrictEqual(parseClockTime('12:30 AM'), { hours: 0, minutes: 30 });

const from = new Date('2026-08-11T12:00:00Z'); // Tuesday
const wednesdays = nextWeeklyOccurrences('Wednesday', '5:00 PM', 2, from);
assert.strictEqual(wednesdays.length, 2);
assert.strictEqual(wednesdays[0].getDay(), 3);
assert.ok(wednesdays[0].getTime() > from.getTime());

// Comediq recurring comedy mics
const comediqEvents = parseComediqMics(
  [
    {
      uniqueIdentifier: 'mic-1',
      openMic: "Producer's Club",
      venueName: "Producer's Club",
      city: 'New York',
      day: 'Wednesday',
      startTime: '5:00 PM',
      location: '358 W 44th St, New York, NY',
      latitude: 40.76,
      longitude: -73.99,
      cost: '$5 cash',
      signUpInstructions: 'in person only',
      hosts: 'Dee Major',
    },
  ],
  { from, occurrences: 2 }
);
assert.strictEqual(comediqEvents.length, 2);
assert.strictEqual(comediqEvents[0].source, 'comediq');
assert.strictEqual(comediqEvents[0].category, 'comedy');
assert.ok(comediqEvents[0].url.includes('comediq.us/open-mics?mic=mic-1'));
assert.strictEqual(normalizeComediqCity('Upstate NY'), 'New York');
assert.strictEqual(normalizeComediqCity('Los Angeles'), 'Los Angeles');

// Do512 open-mic filter
const do512 = parseDo512Events({
  events: [
    {
      id: 1,
      title: "Cactus Cafe Songwriters' Open Mic",
      permalink: '/events/2026/8/11/cactus-cafe-open-mic',
      excerpt: 'Weekly open mic',
      begin_time: '2026-08-11T19:30:00-05:00',
      venue: {
        title: 'Cactus Cafe',
        latitude: 30.28,
        longitude: -97.74,
        full_address: '2247 Guadalupe St., Austin, TX',
        city: 'Austin',
      },
    },
    {
      id: 2,
      title: 'NE-YO & AKON Tour',
      permalink: '/events/2026/8/11/ne-yo',
      excerpt: 'Arena tour',
      begin_time: '2026-08-11T20:00:00-05:00',
      venue: { title: 'Moody', city: 'Austin' },
    },
  ],
});
assert.strictEqual(do512.length, 1);
assert.strictEqual(do512[0].source, 'do512');
assert.strictEqual(do512[0].city, 'Austin');

console.log('✓ scrape_open_mics parser tests passed');
console.log('  fixture path hint:', path.join(__dirname, 'scrape_open_mics.test.js'));
