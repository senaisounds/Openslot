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

export type ScrapeSource = 'eventbrite' | 'comediq' | 'do512';

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
  source: ScrapeSource;
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

interface ComediqMic {
  id?: string;
  uniqueIdentifier?: string;
  openMic?: string;
  venueName?: string;
  city?: string;
  day?: string;
  startTime?: string;
  latestEndTime?: string;
  location?: string;
  latitude?: number | null;
  longitude?: number | null;
  cost?: string | null;
  stageTime?: string | null;
  signUpInstructions?: string | null;
  hosts?: string | null;
  frequency?: string | null;
  status?: string | null;
  borough?: string | null;
  neighborhood?: string | null;
  cover_image_url?: string | null;
}

interface Do512Event {
  id?: number;
  title?: string;
  permalink?: string;
  excerpt?: string;
  description?: string;
  category?: string;
  begin_time?: string;
  is_free?: boolean;
  imagery?: { aws?: { cover_image_w_1200_h_450?: string } };
  venue?: {
    title?: string;
    latitude?: number;
    longitude?: number;
    full_address?: string;
    address?: string;
    city?: string;
    state?: string;
  };
}

const USER_AGENT =
  'Mozilla/5.0 (compatible; OpenSlotBot/1.0; +https://openslot.app)';
const BROWSER_USER_AGENT =
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

const DAY_NAME_TO_INDEX: Record<string, number> = {
  sunday: 0,
  monday: 1,
  tuesday: 2,
  wednesday: 3,
  thursday: 4,
  friday: 5,
  saturday: 6,
};

const COMEDIQ_CITY_ALIASES: Record<string, string> = {
  'New York': 'New York',
  'Los Angeles': 'Los Angeles',
  'Upstate NY': 'New York',
  Riverside: 'Los Angeles',
  'Rancho Cucamonga': 'Los Angeles',
  'Island Park': 'New York',
};

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

function looksLikeOpenMic(name: string, description = ''): boolean {
  return /open\s*-?\s*mic/i.test(`${name} ${description}`);
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

function parseCoordinate(value: string | number | undefined | null): number {
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

/** Parse "6:00 PM" / "18:00" into 24h hours+minutes. */
export function parseClockTime(raw: string | undefined | null): { hours: number; minutes: number } {
  if (!raw) return { hours: 19, minutes: 0 };
  const trimmed = raw.trim();
  const match12 = trimmed.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
  if (match12) {
    let hours = Number(match12[1]) % 12;
    if (match12[3].toUpperCase() === 'PM') hours += 12;
    return { hours, minutes: Number(match12[2]) };
  }
  const match24 = trimmed.match(/^(\d{1,2}):(\d{2})$/);
  if (match24) {
    return { hours: Number(match24[1]), minutes: Number(match24[2]) };
  }
  return { hours: 19, minutes: 0 };
}

/**
 * Next weekly occurrences for a weekday + clock time.
 * Returns up to `count` future dates starting from `from`.
 */
export function nextWeeklyOccurrences(
  dayName: string,
  startTime: string,
  count = 2,
  from: Date = new Date()
): Date[] {
  const dayIndex = DAY_NAME_TO_INDEX[dayName.trim().toLowerCase()];
  if (dayIndex === undefined) return [];
  const { hours, minutes } = parseClockTime(startTime);
  const results: Date[] = [];

  for (let weekOffset = 0; weekOffset < count + 2 && results.length < count; weekOffset += 1) {
    const candidate = new Date(from);
    const delta = (dayIndex - candidate.getDay() + 7) % 7;
    candidate.setDate(candidate.getDate() + delta + weekOffset * 7);
    candidate.setHours(hours, minutes, 0, 0);
    if (candidate.getTime() <= from.getTime()) {
      continue;
    }
    results.push(candidate);
  }

  return results;
}

/**
 * Extract Event objects from schema.org ItemList JSON-LD payloads
 * (as embedded by Eventbrite discover pages).
 */
export function parseEventbriteJsonLd(
  jsonLdPayloads: unknown[],
  city: string,
  options: { requireOpenMicInTitle?: boolean; sourcePath?: string } = {}
): ScrapedOpenMic[] {
  const results: ScrapedOpenMic[] = [];
  const seenUrls = new Set<string>();
  const requireOpenMic = options.requireOpenMicInTitle === true;

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
      if (requireOpenMic && !looksLikeOpenMic(name, item.description || '')) continue;
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

/** Eventbrite comedy category, keeping only listings that look like open mics. */
export async function fetchEventbriteComedyOpenMics(
  city: string,
  slug: string,
  fetchImpl: typeof fetch = fetch
): Promise<ScrapedOpenMic[]> {
  const url = `https://www.eventbrite.com/d/${slug}/comedy/`;
  const response = await fetchImpl(url, {
    headers: {
      'User-Agent': USER_AGENT,
      Accept: 'text/html,application/xhtml+xml',
      'Accept-Language': 'en-US,en;q=0.9',
    },
  });

  if (!response.ok) {
    throw new Error(`Eventbrite comedy ${city} HTTP ${response.status}`);
  }

  const html = await response.text();
  return parseEventbriteJsonLd(extractJsonLdPayloads(html), city, {
    requireOpenMicInTitle: true,
  });
}

/** Normalize Comediq city labels onto OpenSlot major-city names. */
export function normalizeComediqCity(raw: string | undefined | null): string {
  if (!raw) return 'New York';
  return COMEDIQ_CITY_ALIASES[raw] || raw;
}

/**
 * Convert Comediq weekly/monthly mic rows into dated OpenSlot events
 * for the next couple of occurrences.
 */
export function parseComediqMics(
  rows: ComediqMic[],
  options: { from?: Date; occurrences?: number } = {}
): ScrapedOpenMic[] {
  const from = options.from || new Date();
  const occurrences = options.occurrences ?? 2;
  const results: ScrapedOpenMic[] = [];

  for (const row of rows) {
    const id = (row.uniqueIdentifier || row.id || '').trim();
    const name = (row.openMic || row.venueName || '').trim();
    if (!id || !name) continue;

    const city = normalizeComediqCity(row.city);
    const venueName = (row.venueName || name).trim();
    const address = (row.location || `${venueName}, ${city}`).trim();
    const lat = parseCoordinate(row.latitude);
    const lng = parseCoordinate(row.longitude);
    const startTime = row.startTime || '7:00 PM';
    const day = row.day || '';

    const dates = nextWeeklyOccurrences(day, startTime, occurrences, from);
    if (dates.length === 0) continue;

    const details = [
      row.signUpInstructions ? `Sign-up: ${row.signUpInstructions}` : '',
      row.cost ? `Cost: ${row.cost}` : '',
      row.stageTime ? `Stage time: ${row.stageTime}` : '',
      row.hosts ? `Host: ${row.hosts}` : '',
      row.borough ? `Borough: ${row.borough}` : '',
      row.neighborhood ? `Neighborhood: ${row.neighborhood}` : '',
      'Source: Comediq comedy open mic directory.',
    ]
      .filter(Boolean)
      .join('\n');

    for (const startDate of dates) {
      const isoDay = startDate.toISOString().slice(0, 10);
      results.push({
        name: name.slice(0, 99),
        description: details.slice(0, 2000),
        url: `https://comediq.us/open-mics?mic=${encodeURIComponent(id)}&date=${isoDay}`,
        startDate,
        address: address.slice(0, 300),
        venueName: venueName.slice(0, 120),
        lat,
        lng,
        image: row.cover_image_url || '',
        source: 'comediq',
        city,
        category: 'comedy',
      });
    }
  }

  return results;
}

export async function fetchComediqOpenMics(
  fetchImpl: typeof fetch = fetch
): Promise<ScrapedOpenMic[]> {
  // Prefer public static dump (same data Comediq serves to anonymous users).
  const response = await fetchImpl('https://comediq.us/mics.json', {
    headers: {
      'User-Agent': USER_AGENT,
      Accept: 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error(`Comediq mics.json HTTP ${response.status}`);
  }

  const payload = await response.json();
  if (!Array.isArray(payload)) {
    throw new Error('Comediq mics.json did not return an array');
  }

  return parseComediqMics(payload as ComediqMic[]);
}

export function parseDo512Events(payload: { events?: Do512Event[] }): ScrapedOpenMic[] {
  const results: ScrapedOpenMic[] = [];
  for (const event of payload.events || []) {
    const title = (event.title || '').trim();
    const excerpt = (event.excerpt || event.description || '').replace(/<[^>]+>/g, ' ');
    if (!title || !looksLikeOpenMic(title, excerpt)) continue;
    if (!event.begin_time || !event.permalink) continue;

    const startDate = new Date(event.begin_time);
    if (Number.isNaN(startDate.getTime())) continue;

    const venue = event.venue || {};
    const address =
      venue.full_address ||
      [venue.address, venue.city, venue.state].filter(Boolean).join(', ');

    results.push({
      name: title.slice(0, 99),
      description: excerpt.trim().slice(0, 2000),
      url: event.permalink.startsWith('http')
        ? event.permalink
        : `https://do512.com${event.permalink}`,
      startDate,
      address: address.slice(0, 300),
      venueName: (venue.title || 'Austin Venue').slice(0, 120),
      lat: parseCoordinate(venue.latitude),
      lng: parseCoordinate(venue.longitude),
      image: event.imagery?.aws?.cover_image_w_1200_h_450 || '',
      source: 'do512',
      city: venue.city || 'Austin',
      category: inferCategory(title, excerpt),
    });
  }
  return results;
}

/** Soft Austin comedy calendar source (Do512). Filters to open-mic titles. */
export async function fetchDo512OpenMics(
  fetchImpl: typeof fetch = fetch
): Promise<ScrapedOpenMic[]> {
  const found: ScrapedOpenMic[] = [];
  const seen = new Set<string>();

  for (const page of [1, 2, 3]) {
    const url = `https://do512.com/events.json?category=comedy&page=${page}`;
    const response = await fetchImpl(url, {
      headers: {
        'User-Agent': BROWSER_USER_AGENT,
        Accept: 'application/json,text/javascript,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        Referer: 'https://do512.com/events/comedy',
      },
    });
    if (!response.ok) {
      throw new Error(`Do512 comedy page ${page} HTTP ${response.status}`);
    }
    const payload = (await response.json()) as { events?: Do512Event[] };
    const pageEvents = parseDo512Events(payload);
    if ((payload.events || []).length === 0) break;

    for (const event of pageEvents) {
      if (seen.has(event.url)) continue;
      seen.add(event.url);
      found.push(event);
    }

    // Do512 often ignores filters; stop early if pages look identical.
    if (page > 1 && pageEvents.length === 0) break;
  }

  return found;
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

async function runSource(
  label: { city: string; source: string },
  fetcher: () => Promise<ScrapedOpenMic[]>,
  db: admin.firestore.Firestore
): Promise<{ result: ScrapeRunResult; upserted: number }> {
  const result: ScrapeRunResult = {
    city: label.city,
    source: label.source,
    found: 0,
    upserted: 0,
    skipped: 0,
    errors: [],
  };

  try {
    const found = await fetcher();
    result.found = found.length;
    const { upserted, skipped } = await upsertScrapedEvents(found, db);
    result.upserted = upserted;
    result.skipped = skipped;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    result.errors.push(message);
    console.error(`Open mic scrape failed for ${label.source}/${label.city}:`, message);
  }

  return { result, upserted: result.upserted };
}

export async function scrapeOpenMicsForCities(
  cities: Record<string, string> = EVENTBRITE_CITY_SLUGS,
  options: {
    fetchImpl?: typeof fetch;
    db?: admin.firestore.Firestore;
    delayMs?: number;
    includeComediq?: boolean;
    includeDo512?: boolean;
    includeEventbriteComedy?: boolean;
  } = {}
): Promise<{ results: ScrapeRunResult[]; totalUpserted: number }> {
  const fetchImpl = options.fetchImpl || fetch;
  const db = options.db || admin.firestore();
  const delayMs = options.delayMs ?? 1500;
  const includeComediq = options.includeComediq !== false;
  const includeDo512 = options.includeDo512 !== false;
  const includeEventbriteComedy = options.includeEventbriteComedy !== false;
  const results: ScrapeRunResult[] = [];
  let totalUpserted = 0;

  if (includeComediq) {
    const { result, upserted } = await runSource(
      { city: 'NYC+LA', source: 'comediq' },
      () => fetchComediqOpenMics(fetchImpl),
      db
    );
    results.push(result);
    totalUpserted += upserted;
  }

  if (includeDo512) {
    const { result, upserted } = await runSource(
      { city: 'Austin', source: 'do512' },
      () => fetchDo512OpenMics(fetchImpl),
      db
    );
    results.push(result);
    totalUpserted += upserted;
  }

  const entries = Object.entries(cities);
  for (let index = 0; index < entries.length; index += 1) {
    const [city, slug] = entries[index];

    const openMicRun = await runSource(
      { city, source: 'eventbrite' },
      () => fetchEventbriteOpenMics(city, slug, fetchImpl),
      db
    );
    results.push(openMicRun.result);
    totalUpserted += openMicRun.upserted;

    if (includeEventbriteComedy) {
      if (delayMs > 0) await sleep(Math.min(delayMs, 800));
      const comedyRun = await runSource(
        { city, source: 'eventbrite-comedy' },
        () => fetchEventbriteComedyOpenMics(city, slug, fetchImpl),
        db
      );
      results.push(comedyRun.result);
      totalUpserted += comedyRun.upserted;
    }

    if (index < entries.length - 1 && delayMs > 0) {
      await sleep(delayMs);
    }
  }

  await db.collection('system').doc('scrape_runs').set(
    {
      lastRunAt: admin.firestore.FieldValue.serverTimestamp(),
      lastResults: results,
      totalUpserted,
      sources: ['comediq', 'do512', 'eventbrite', 'eventbrite-comedy'],
    },
    { merge: true }
  );

  return { results, totalUpserted };
}
