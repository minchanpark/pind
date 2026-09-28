export function explicitGoogleAction(body: Record<string, unknown>): boolean {
  return body.userInitiated === true && ['google_search','resolve','detail'].includes(String(body.action));
}
export function dailyLimit(raw: string | undefined, fallback: number): number {
  if (raw === undefined) return fallback;
  const value = Number(raw);
  return Number.isSafeInteger(value) && value > 0 ? value : 0;
}
