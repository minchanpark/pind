# Google Maps and Places setup

Pind uses two separate Google keys. Never reuse or ship the Places Web Service
key in the mobile app.

At runtime, the Map tab uses Nearby Search (New) to load food venues around the
current viewport whenever the map stops moving within South Korea. Tapping a
place fetches its current Place Details and up to six live place photos. Only
the Google Place ID and Pind's internal reference ID are persisted.

Google Places returns general venue photos, not a reliable structured restaurant
menu or menu-photo classification. Pind therefore labels Google images as place
photos and builds the menu-photo section only from Pind logs that contain a dish
name and user-uploaded food photo.

## 1. Enable Google services

In one billing-enabled Google Cloud project, enable:

- Places API (New)
- Maps SDK for iOS
- Maps SDK for Android when Android work starts

Google setup references:

- [Places API setup](https://developers.google.com/maps/documentation/places/web-service/cloud-setup)
- [Expo react-native-maps setup](https://docs.expo.dev/versions/v57.0.0/sdk/map-view/)

## 2. Create the iOS map key

Create an API key with:

- Application restriction: iOS apps
- Bundle identifier: `com.pind.app`
- API restriction: Maps SDK for iOS

Add it to `mobile/.env.local`:

```dotenv
GOOGLE_MAPS_IOS_API_KEY=your_ios_restricted_key
EXPO_PUBLIC_GOOGLE_MAPS_ENABLED=true
```

The native key is applied by `mobile/app.config.ts`. Rebuild the native app
after changing it:

```sh
cd mobile
npx expo prebuild --platform ios
npm run ios:native
```

If Xcode exits with code 70 and says its bundled iOS version is not installed,
install the matching simulator runtime (omit `-buildVersion` so Xcode selects
the compatible build):

```sh
xcodebuild -downloadPlatform iOS
```

## 3. Create the server Places key

Create another API key restricted to Places API (New). This key cannot have an
iOS/Android application restriction because Supabase calls Google from the
server. Keep quotas and billing alerts enabled.

Set it as a hosted Supabase Edge Function secret:

```sh
npx supabase secrets set GOOGLE_PLACES_API_KEY=your_server_key \
  --project-ref mkfgqobwededpzdekvxg
```

Do not put `GOOGLE_PLACES_API_KEY` in `mobile/.env.local`, app config, source
code, or an `EXPO_PUBLIC_` variable. The deployed `google-places` function sees
new secrets immediately and does not need another deployment.

If the app reports `GOOGLE_PERMISSION_DENIED`, verify all three server-key
requirements:

- Places API (New) is enabled in the key's Google Cloud project.
- Billing is active for that project.
- The key has an API restriction for Places API (New), but no iOS, Android,
  website, or IP application restriction.

## 4. Before TestFlight

- Confirm the Google map is visible and its built-in attribution is unobscured.
- Search and select a real venue, create a MyLog, relaunch, and confirm the log
  returns on the map with freshly hydrated place content.
- Add public Terms of Use and Privacy Policy pages that incorporate the Google
  Maps terms and privacy requirements.
- Set Google Cloud quota limits and budget alerts.

Pind stores only the Google Place ID. Place names, addresses, coordinates,
photo references, and photo URLs are fetched when needed and are not persisted
in Postgres.
