"use strict";
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.EVENTBRITE_CITY_SLUGS = exports.SCRAPER_HOST_ID = void 0;
exports.scrapedEventId = scrapedEventId;
exports.inferCategory = inferCategory;
exports.parseEventbriteJsonLd = parseEventbriteJsonLd;
exports.extractJsonLdPayloads = extractJsonLdPayloads;
exports.fetchEventbriteOpenMics = fetchEventbriteOpenMics;
exports.scrapedEventToFirestoreData = scrapedEventToFirestoreData;
exports.scrapedEventRefreshData = scrapedEventRefreshData;
exports.upsertScrapedEvents = upsertScrapedEvents;
exports.scrapeOpenMicsForCities = scrapeOpenMicsForCities;
const crypto = require("crypto");
const admin = require("firebase-admin");
/** System host id for events discovered by the web scraper. */
exports.SCRAPER_HOST_ID = 'openslot_web_scraper';
/** Cities OpenSlot already supports, mapped to Eventbrite discover slugs. */
exports.EVENTBRITE_CITY_SLUGS = {
    'New York': 'ny--new-york',
    'Los Angeles': 'ca--los-angeles',
    Chicago: 'il--chicago',
    Houston: 'tx--houston',
    Philadelphia: 'pa--philadelphia',
    Phoenix: 'az--phoenix',
    'San Antonio': 'tx--san-antonio',
    'San Diego': 'ca--san-diego',
    Dallas: 'tx--dallas',
    'San Francisco': 'ca--san-francisco',
};
const USER_AGENT = 'OpenSlotBot/1.0 (+https://openslot.app; open-mic discovery; respectful crawl)';
function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
/** Stable Firestore doc id derived from the source listing URL. */
function scrapedEventId(url) {
    const hash = crypto.createHash('sha256').update(url.trim()).digest('hex').slice(0, 20);
    return `scraped_${hash}`;
}
function inferCategory(name, description) {
    const text = `${name} ${description}`.toLowerCase();
    if (/\b(comedy|comedian|stand[- ]?up|improv)\b/.test(text))
        return 'comedy';
    if (/\b(poetry|spoken word|poet)\b/.test(text))
        return 'poetry';
    if (/\b(music|singer|songwriter|band|acoustic|hip[- ]?hop|rap)\b/.test(text)) {
        return 'music';
    }
    return 'other';
}
function formatAddress(location) {
    if (!location)
        return '';
    const address = location.address;
    const parts = [
        address === null || address === void 0 ? void 0 : address.streetAddress,
        address === null || address === void 0 ? void 0 : address.addressLocality,
        address === null || address === void 0 ? void 0 : address.addressRegion,
        address === null || address === void 0 ? void 0 : address.postalCode,
    ].filter((part) => !!part && part.trim().length > 0);
    if (parts.length > 0)
        return parts.join(', ');
    return location.name || '';
}
function parseCoordinate(value) {
    if (typeof value === 'number' && Number.isFinite(value))
        return value;
    if (typeof value === 'string' && value.trim()) {
        const parsed = Number(value);
        if (Number.isFinite(parsed))
            return parsed;
    }
    return 0;
}
function firstImage(image) {
    var _a;
    if (Array.isArray(image))
        return ((_a = image.find((item) => !!item)) === null || _a === void 0 ? void 0 : _a.toString()) || '';
    return image || '';
}
/**
 * Extract Event objects from schema.org ItemList JSON-LD payloads
 * (as embedded by Eventbrite discover pages).
 */
function parseEventbriteJsonLd(jsonLdPayloads, city) {
    var _a, _b, _c, _d, _e;
    const results = [];
    const seenUrls = new Set();
    for (const payload of jsonLdPayloads) {
        if (!payload || typeof payload !== 'object')
            continue;
        const list = payload;
        if (list['@type'] !== 'ItemList' || !Array.isArray(list.itemListElement)) {
            continue;
        }
        for (const element of list.itemListElement) {
            const item = element === null || element === void 0 ? void 0 : element.item;
            if (!item || item['@type'] !== 'Event')
                continue;
            const name = (item.name || '').trim();
            const url = (item.url || '').trim();
            if (!name || !url)
                continue;
            if (!/open\s*mic/i.test(`${name} ${item.description || ''}`)) {
                // Eventbrite discover pages are already /open-mic/ filtered, but keep a soft check.
                // Still accept if the listing page is the open-mic discover feed.
            }
            if (seenUrls.has(url))
                continue;
            seenUrls.add(url);
            const startRaw = item.startDate;
            if (!startRaw)
                continue;
            const startDate = new Date(startRaw);
            if (Number.isNaN(startDate.getTime()))
                continue;
            const description = (item.description || '').trim();
            const venueName = (((_a = item.location) === null || _a === void 0 ? void 0 : _a.name) || 'Open Mic Venue').trim();
            const lat = parseCoordinate((_c = (_b = item.location) === null || _b === void 0 ? void 0 : _b.geo) === null || _c === void 0 ? void 0 : _c.latitude);
            const lng = parseCoordinate((_e = (_d = item.location) === null || _d === void 0 ? void 0 : _d.geo) === null || _e === void 0 ? void 0 : _e.longitude);
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
function extractJsonLdPayloads(html) {
    const payloads = [];
    const pattern = /<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
    let match;
    while ((match = pattern.exec(html)) !== null) {
        const raw = match[1].trim();
        if (!raw)
            continue;
        try {
            payloads.push(JSON.parse(raw));
        }
        catch (error) {
            console.warn('Failed to parse JSON-LD block', error);
        }
    }
    return payloads;
}
async function fetchEventbriteOpenMics(city, slug, fetchImpl = fetch) {
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
function scrapedEventToFirestoreData(event, now = new Date()) {
    const ended = event.startDate.getTime() < now.getTime() - 6 * 60 * 60 * 1000;
    return {
        name: event.name,
        host: exports.SCRAPER_HOST_ID,
        description: event.description ||
            `Open mic discovered on ${event.source}. Sign up and details are on the original listing.`,
        rules: 'This listing was discovered from the public web. Reserve or sign up on the original page — details may change.',
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
function scrapedEventRefreshData(event, now = new Date()) {
    const full = scrapedEventToFirestoreData(event, now);
    const { attendees: _attendees, waitlist: _waitlist, reservationTimestamps: _reservationTimestamps, checkedPerformers: _checkedPerformers, checkedPerformersList: _checkedPerformersList, performer: _performer, performerStart: _performerStart, live: _live } = full, refresh = __rest(full, ["attendees", "waitlist", "reservationTimestamps", "checkedPerformers", "checkedPerformersList", "performer", "performerStart", "live"]);
    return refresh;
}
async function upsertScrapedEvents(events, db = admin.firestore()) {
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
        const refs = chunk.map((event) => db.collection('events').doc(scrapedEventId(event.url)));
        const existing = await db.getAll(...refs);
        const batch = db.batch();
        chunk.forEach((event, index) => {
            const ref = refs[index];
            if (existing[index].exists) {
                batch.set(ref, scrapedEventRefreshData(event, now), { merge: true });
            }
            else {
                batch.set(ref, scrapedEventToFirestoreData(event, now));
            }
            upserted += 1;
        });
        await batch.commit();
    }
    return { upserted, skipped };
}
async function scrapeOpenMicsForCities(cities = exports.EVENTBRITE_CITY_SLUGS, options = {}) {
    var _a;
    const fetchImpl = options.fetchImpl || fetch;
    const db = options.db || admin.firestore();
    const delayMs = (_a = options.delayMs) !== null && _a !== void 0 ? _a : 1500;
    const results = [];
    let totalUpserted = 0;
    const entries = Object.entries(cities);
    for (let index = 0; index < entries.length; index += 1) {
        const [city, slug] = entries[index];
        const cityResult = {
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
        }
        catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            cityResult.errors.push(message);
            console.error(`Open mic scrape failed for ${city}:`, message);
        }
        results.push(cityResult);
        if (index < entries.length - 1 && delayMs > 0) {
            await sleep(delayMs);
        }
    }
    await db.collection('system').doc('scrape_runs').set({
        lastRunAt: admin.firestore.FieldValue.serverTimestamp(),
        lastResults: results,
        totalUpserted,
        source: 'eventbrite',
    }, { merge: true });
    return { results, totalUpserted };
}
//# sourceMappingURL=scrape_open_mics.js.map