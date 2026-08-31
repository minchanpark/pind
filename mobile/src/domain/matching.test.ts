import assert from 'node:assert/strict';
import test from 'node:test';

import { matchPlace, rankPlaces } from './matching';
import type { Place, TasteTag } from './types';

const spicy: TasteTag = {
  code: 'spicy',
  axis: 'taste',
  labelEn: 'Spicy',
  labelKo: '매콤',
  emoji: '🌶️',
  sortOrder: 10,
};

const quiet: TasteTag = {
  code: 'quiet',
  axis: 'vibe',
  labelEn: 'Quiet',
  labelKo: '조용',
  emoji: '🌙',
  sortOrder: 10,
};

function place(name: string, strengths: Array<[TasteTag, number]>): Place {
  return {
    id: name.length,
    slug: name.toLowerCase(),
    provider: 'pind',
    externalPlaceId: null,
    nameEn: name,
    nameKo: name,
    category: 'Korean',
    addressEn: 'South Korea',
    addressKo: '대한민국',
    latitude: 37.5,
    longitude: 127,
    heroImageUrl: 'https://example.com/image.jpg',
    googleMapsUri: null,
    photoGoogleMapsUri: null,
    photoAttributions: [],
    gallery: [],
    shortDescriptionEn: 'Description',
    shortDescriptionKo: '설명',
    businessStatus: null,
    isOpenNow: null,
    weekdayDescriptions: [],
    websiteUri: null,
    phoneNumber: null,
    editorialSummary: null,
    isDemo: true,
    tastes: strengths.map(([tag, strength]) => ({ tag, strength })),
  };
}

test('match score rewards only selected taste signals', () => {
  const result = matchPlace(place('Fire Bowl', [[spicy, 5], [quiet, 1]]), new Set(['spicy']));

  assert.equal(result.score, 98);
  assert.deepEqual(result.reasons.map((reason) => reason.code), ['spicy']);
});

test('ranking puts the strongest taste match first', () => {
  const ranked = rankPlaces(
    [place('Quiet Cup', [[quiet, 5]]), place('Fire Bowl', [[spicy, 5]])],
    new Set(['spicy']),
  );

  assert.equal(ranked[0].nameEn, 'Fire Bowl');
});
