import type { MatchResult, Place } from './types';

export function matchPlace(place: Place, selectedCodes: ReadonlySet<string>): MatchResult {
  if (selectedCodes.size === 0) {
    return { score: 0, reasons: [] };
  }

  const matchingTastes = place.tastes
    .filter(({ tag }) => selectedCodes.has(tag.code))
    .sort((a, b) => b.strength - a.strength);

  const earned = matchingTastes.reduce((total, taste) => total + taste.strength, 0);
  const possible = selectedCodes.size * 5;
  const score = Math.min(98, Math.round(42 + (earned / possible) * 56));

  return {
    score,
    reasons: matchingTastes.slice(0, 3).map(({ tag }) => tag),
  };
}

export function rankPlaces(places: readonly Place[], selectedCodes: ReadonlySet<string>): Place[] {
  return [...places].sort((left, right) => {
    const scoreDifference = matchPlace(right, selectedCodes).score - matchPlace(left, selectedCodes).score;
    return scoreDifference || left.nameEn.localeCompare(right.nameEn);
  });
}
