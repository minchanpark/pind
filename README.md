# Pind

Pind is an English-first Korea food discovery app that recommends places from a
visitor's taste signals instead of star ratings.

## Fast MVP

The current vertical slice lets a visitor:

1. choose at least three taste signals;
2. explore live Google restaurants, cafes, bakeries, and dessert shops with pinch/button zoom and optional current-location recentering as the map moves anywhere in South Korea;
3. open a place photo PIN and read venue details, a live Google photo gallery, and menu photos contributed through Pind logs;
4. switch to the **Logs** tab to browse post-style logs from the visitor, friends, and Pind;
5. create a photo-based taste log after explicitly choosing a real Google place;
6. read, edit, and delete their own logs from the same feed.

The client is Expo SDK 57 with React Native and TypeScript. Discovery and post
data are connected to Supabase. Supabase anonymous Auth owns writes, RLS
protects each visitor's content, Storage holds post photos, and the taste
profile remains on the device. Google place lookup runs through an authenticated
Edge Function so the Places key is never included in the mobile bundle.

## Run locally

```sh
cd mobile
cp .env.example .env.local
# Add the Supabase publishable key to .env.local.
npm install
npm run ios
```

`npm run ios` builds the native app so the Google Maps renderer is available.
Use `npm run ios:go` for the faster Expo Go loop; Google place search and photos
work there, but its iOS map uses Apple's renderer. Native key setup is described
in `doc/google-maps-setup.md`.

Run the automated checks with:

```sh
cd mobile
npm run verify
```

## Project references

- Product requirements: `doc/prd.md`
- MVP decisions and deferred scope: `doc/fast-mvp-decisions.md`
- Google Maps and Places setup: `doc/google-maps-setup.md`
- Database migrations: `supabase/migrations/`

This build is demo-ready. The current development project has Google Maps and
Places configured and verified; a fresh environment remains configuration-gated
until Google Cloud billing and both keys are supplied.
Production phone/Apple authentication, friend-management UI, and production
analytics are intentionally deferred.
