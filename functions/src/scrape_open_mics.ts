import * as crypto from 'crypto';
import * as admin from 'firebase-admin';

/** System host id for events discovered by the web scraper. */
export const SCRAPER_HOST_ID = 'openslot_web_scraper';

/**
 * Major US cities mapped to Eventbrite discover slugs.
 * Includes New York, Austin, Los Angeles, and other large markets.
 */
export const EVENTBRITE_CITY_SLUGS: Record<string, string> = {
  'New York': 'ny--new-york',
  'Los Angeles': 'ca--los-angeles',
  Austin: 'tx--austin',
  Chicago: 'il--chicago',
  Houston: 'tx--houston',
  Philadelphia: 'pa--philadelphia',
  Phoenix: 'az--phoenix',
  'San Antonio': 'tx--san-antonio',
  'San Diego': 'ca--san-diego',
  Dallas: 'tx--dallas',
  'San Francisco': 'ca--san-francisco',
  Miami: 'fl--miami',
  Seattle: 'wa--seattle',
  Boston: 'ma--boston',
  Denver: 'co--denver',
  Atlanta: 'ga--atlanta',
  Nashville: 'tn--nashville',
  Portland: 'or--portland',
  Washington: 'dc--washington',
  'Las Vegas': 'nv--las-vegas',
  Detroit: 'mi--detroit',
  Minneapolis: 'mn--minneapolis',
};

export interface ScrapedOpenMic {
  name: string;
  description: string;
  url: string;
  startDate: Date;
  address: string;
  venueName: string;
  lat: number;
  lng: number;
  image: string;
  source: 'eventbrite';
  city: string;
  category: string;
}

export interface ScrapeRunResult {
  city: string;
  source: string;
  found: number;
  upserted: number;
  skipped: number;
  errors: string[];
}

interface JsonLdEvent {
  '@type'?: string;
  name?: string;
  description?: string;
  url?: string;
  startDate?: string;
  endDate?: string;
  image?: string | string[];
  location?: {
    '@type'?: string;
    name?: string;
    geo?: {
      latitude?: string | number;
      longitude?: string | number;
    };
    address?: {
      streetAddress?: string;
      addressLocality?: string;
      addressRegion?: string;
      postalCode?: string;
      addressCountry?: string;
    };
  };
}

interface JsonLdItemList {
  '@type'?: string;
  itemListElement?: Array<{
    '@type'?: string;
    item?: JsonLdEvent;
  }>;
}

const USER_AGENT =
  'OpenSlotBot/1.0 (+https://openslot.app; open-mic discovery; respectful crawl)';

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/** Stable Firestore doc id derived from the source listing URL. */
export function scrapedEventId(url: string): string {
  const hash = crypto.createHash('sha256').update(url.trim()).digest('hex').slice(0, 20);
  return `scraped_${hash}`;
}

export function inferCategory(name: string, description: string): string {
  const text = `${name} ${description}`.toLowerCase();
  if (/\b(comedy|comedian|stand[- ]?up|improv)\b/.test(text)) return 'comedy';
  if (/\b(poetry|spoken word|poet)\b/.test(text)) return 'poetry';
  if (/\b(music|singer|songwriter|band|acoustic|hip[- ]?hop|rap)\b/.test(text)) {
    return 'music';
  }
  return 'other';
}

function formatAddress(location: JsonLdEvent['location']): string {
  if (!location) return '';
  const address = location.address;
  const parts = [
    address?.streetAddress,
    address?.addressLocality,
    address?.addressRegion,
    address?.postalCode,
  ].filter((part): part is string => !!part && part.trim().length > 0);
  if (parts.length > 0) return parts.join(', ');
  return location.name || '';
}

function parseCoordinate(value: string | number | undefined): number {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return 0;
}

function firstImage(image: string | string[] | undefined): string {
  if (Array.isArray(image)) return image.find((item) => !!item)?.toString() || '';
  return image || '';
}

/**
 * Extract Event objects from schema.org ItemList JSON-LD payloads
 * (as embedded by Eventbrite discover pages).
 */
export function parseEventbriteJsonLd(
  jsonLdPayloads: unknown[],
  city: string
): ScrapedOpenMic[] {
  const results: ScrapedOpenMic[] = [];
  const seenUrls = new Set<string>();

  for (const payload of jsonLdPayloads) {
    if (!payload || typeof payload !== 'object') continue;
    const list = payload as JsonLdItemList;
    if (list['@type'] !== 'ItemList' || !Array.isArray(list.itemListElement)) {
      continue;
    }

    for (const element of list.itemListElement) {
      const item = element?.item;
      if (!item || item['@type'] !== 'Event') continue;

      const name = (item.name || '').trim();
      const url = (item.url || '').trim();
      if (!name || !url) continue;
      if (!/open\s*mic/i.test(`${name} ${item.description || ''}`)) {
        // Eventbrite discover pages are already /open-mic/ filtered, but keep a soft check.
        // Still accept if the listing page is the open-mic discover feed.
      }
      if (seenUrls.has(url)) continue;
      seenUrls.add(url);

      const startRaw = item.startDate;
      if (!startRaw) continue;
      const startDate = new Date(startRaw);
      if (Number.isNaN(startDate.getTime())) continue;

      const description = (item.description || '').trim();
      const venueName = (item.location?.name || 'Open Mic Venue').trim();
      const lat = parseCoordinate(item.location?.geo?.latitude);
      const lng = parseCoordinate(item.location?.geo?.longitude);

      results.push({
        name: name.slice(0, 99),
        description: description.slice(0, 2000),
        url,
        startDate,
        address: formatAddress(item.location).slice(0, 300),
        venueName: venueName.slice(0, 120),
        lat,
        lng,
        image: firstImage(item.image),
        source: 'eventbrite',
        city,
        category: inferCategory(name, description),
      });
    }
  }

  return results;
}

/** Pull all application/ld+json script bodies from an HTML document. */
export function extractJsonLdPayloads(html: string): unknown[] {
  const payloads: unknown[] = [];
  const pattern =
    /<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(html)) !== null) {
    const raw = match[1].trim();
    if (!raw) continue;
    try {
      payloads.push(JSON.parse(raw));
    } catch (error) {
      console.warn('Failed to parse JSON-LD block', error);
    }
  }
  return payloads;
}

export async function fetchEventbriteOpenMics(
  city: string,
  slug: string,
  fetchImpl: typeof fetch = fetch
): Promise<ScrapedOpenMic[]> {
  const url = `https://www.eventbrite.com/d/${slug}/open-mic/`;
  const response = await fetchImpl(url, {
    headers: {
      'User-Agent': USER_AGENT,
      Accept: 'text/html,application/xhtml+xml',
      'Accept-Language': 'en-US,en;q=0.9',
    },
  });

  if (!response.ok) {
    throw new Error(`Eventbrite ${city} HTTP ${response.status}`);
  }

  const html = await response.text();
  return parseEventbriteJsonLd(extractJsonLdPayloads(html), city);
}

export function scrapedEventToFirestoreData(
  event: ScrapedOpenMic,
  now: Date = new Date()
): Record<string, unknown> {
  const ended = event.startDate.getTime() < now.getTime() - 6 * 60 * 60 * 1000;
  return {
    name: event.name,
    host: SCRAPER_HOST_ID,
    description:
      event.description ||
      `Open mic discovered on ${event.source}. Sign up and details are on the original listing.`,
    rules:
      'This listing was discovered from the public web. Reserve or sign up on the original page — details may change.',
    location: new admin.firestore.GeoPoint(event.lat || 0, event.lng || 0),
    date: admin.firestore.Timestamp.fromDate(event.startDate),
    live: false,
    ended,
    performer: null,
    performerStart: null,
    timeLimit: 0,
    attendees: [],
    reservationTimestamps: {},
    checkedPerformers: [],
    checkedPerformersList: [],
    address: event.address || event.city,
    category: event.category,
    hostName: event.venueName,
    upNext: null,
    price: 0,
    signupOnLocation: true,
    slots: 0,
    type: 'mic',
    waitlist: [],
    isPrivate: false,
    password: null,
    coverUrl: event.image || '',
    isFeatured: false,
    capacity: 0,
    // Discovery metadata
    isScraped: true,
    source: event.source,
    externalUrl: event.url,
    city: event.city,
    scrapedAt: admin.firestore.Timestamp.fromDate(now),
    sourceEventId: scrapedEventId(event.url),
  };
}

/** Fields safe to refresh on every scrape without wiping user state. */
export function scrapedEventRefreshData(
  event: ScrapedOpenMic,
  now: Date = new Date()
): Record<string, unknown> {
  const full = scrapedEventToFirestoreData(event, now);
  const {
    attendees: _attendees,
    waitlist: _waitlist,
    reservationTimestamps: _reservationTimestamps,
    checkedPerformers: _checkedPerformers,
    checkedPerformersList: _checkedPerformersList,
    performer: _performer,
    performerStart: _performerStart,
    live: _live,
    ...refresh
  } = full;
  return refresh;
}

export async function upsertScrapedEvents(
  events: ScrapedOpenMic[],
  db: admin.firestore.Firestore = admin.firestore()
): Promise<{ upserted: number; skipped: number }> {
  let upserted = 0;
  let skipped = 0;
  const now = new Date();
  const validEvents = events.filter((event) => {
    if (!event.url || !event.name) {
      skipped += 1;
      return false;
    }
    return true;
  });

  // Firestore batches are capped at 500 ops; keep headroom for mixed set/update.
  const chunkSize = 200;
  for (let i = 0; i < validEvents.length; i += chunkSize) {
    const chunk = validEvents.slice(i, i + chunkSize);
    const refs = chunk.map((event) =>
      db.collection('events').doc(scrapedEventId(event.url))
    );
    const existing = await db.getAll(...refs);
    const batch = db.batch();

    chunk.forEach((event, index) => {
      const ref = refs[index];
      if (existing[index].exists) {
        batch.set(ref, scrapedEventRefreshData(event, now), { merge: true });
      } else {
        batch.set(ref, scrapedEventToFirestoreData(event, now));
      }
      upserted += 1;
    });

    await batch.commit();
  }

  return { upserted, skipped };
}

export async function scrapeOpenMicsForCities(
  cities: Record<string, string> = EVENTBRITE_CITY_SLUGS,
  options: {
    fetchImpl?: typeof fetch;
    db?: admin.firestore.Firestore;
    delayMs?: number;
  } = {}
): Promise<{ results: ScrapeRunResult[]; totalUpserted: number }> {
  const fetchImpl = options.fetchImpl || fetch;
  const db = options.db || admin.firestore();
  const delayMs = options.delayMs ?? 1500;
  const results: ScrapeRunResult[] = [];
  let totalUpserted = 0;

  const entries = Object.entries(cities);
  for (let index = 0; index < entries.length; index += 1) {
    const [city, slug] = entries[index];
    const cityResult: ScrapeRunResult = {
      city,
      source: 'eventbrite',
      found: 0,
      upserted: 0,
      skipped: 0,
      errors: [],
    };

    try {
      const found = await fetchEventbriteOpenMics(city, slug, fetchImpl);
      cityResult.found = found.length;
      const { upserted, skipped } = await upsertScrapedEvents(found, db);
      cityResult.upserted = upserted;
      cityResult.skipped = skipped;
      totalUpserted += upserted;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      cityResult.errors.push(message);
      console.error(`Open mic scrape failed for ${city}:`, message);
    }

    results.push(cityResult);
    if (index < entries.length - 1 && delayMs > 0) {
      await sleep(delayMs);
    }
  }

  await db.collection('system').doc('scrape_runs').set(
    {
      lastRunAt: admin.firestore.FieldValue.serverTimestamp(),
      lastResults: results,
      totalUpserted,
      source: 'eventbrite',
    },
    { merge: true }
  );

  return { results, totalUpserted };
}
