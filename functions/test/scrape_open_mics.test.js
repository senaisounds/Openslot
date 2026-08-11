/**
 * Lightweight parser tests for open mic discovery (no Firebase required).
 * Run: node test/scrape_open_mics.test.js
 */
const assert = require('assert');
const path = require('path');

// Compile step writes to lib/; for direct TS-less testing we re-implement
// the pure helpers here against the compiled output when available.
let parseEventbriteJsonLd;
let extractJsonLdPayloads;
let scrapedEventId;
let inferCategory;

try {
  ({
    parseEventbriteJsonLd,
    extractJsonLdPayloads,
    scrapedEventId,
    inferCategory,
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

console.log('✓ scrape_open_mics parser tests passed');
console.log('  fixture path hint:', path.join(__dirname, 'scrape_open_mics.test.js'));
