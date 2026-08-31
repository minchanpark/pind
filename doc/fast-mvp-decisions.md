# Pind Fast MVP decisions

## Accepted validation flow

An English-first visitor chooses at least three taste signals, opens a Korea map,
switches from all places to taste-matched places, selects a photo PIN, and sees
the match score and reasons.

- Actor: a visitor to South Korea
- Entry point: first app launch
- Expected outcome: the visitor can choose a place using taste rather than a star rating
- PRD coverage: G-01, G-02, G-03, J-01 steps 3-8, J-02, FR-MAP-001/003-009,
  FR-RC-001/002/005, FR-I18N-001/003

## Decisions for this slice

| Area | Decision | Reason |
| --- | --- | --- |
| Client | Expo SDK 57, React Native, TypeScript | Fastest supported path to iOS now while preserving Android expansion |
| Backend | Existing Supabase project `mkfgqobwededpzdekvxg` | User-selected backend; real Data API boundary |
| Database reset | Previous app schemas and test Auth data removed | The user confirmed the project was unused and approved a clean Pind database |
| Database names | `taste_tags`, `places`, `place_taste_tags` | The project is now Pind-only, so direct domain names are clearer |
| Map | `react-native-maps` with Google Maps in configured native builds | The selected Google Places content must be shown with Google Maps; keyless Expo development keeps a temporary native-map fallback |
| Location | Start in Seoul, then query the current viewport anywhere in South Korea | Keeps a useful first view without limiting discovery to one city or requiring location permission |
| Taste profile | Stored on device for this slice | Auth provider setup is not required to test the discovery proposition |
| Recommendation | Weighted overlap between selected tags and curated place tags | Explainable and testable; no opaque score or star rating |
| Language | English UI with Korean place names and tag labels available in data | Matches the first target while retaining bilingual source data |
| Data | Eight marked demo places plus on-demand Google Places results | The demo remains runnable before keys are configured while real results are never mistaken for fixtures |

## CRUD vertical extension

After choosing a demo place, the visitor can create a taste log with a photo,
menu, reaction emoji, taste tags, and free text. They can read the log in **My
logs**, edit it, and delete it. Creating a log also records a visit.

- Actor: the same visitor, represented by a persistent Supabase anonymous user
- Entry point: `Add a Pind log` in a place detail sheet
- Expected outcome: a real create → read → update → delete loop owned by that visitor
- PRD coverage: G-05, G-07, J-04 steps 1-7 and 9-10,
  FR-PO-001/002/003/004/005/006/007/009/010

| Area | Decision | Reason |
| --- | --- | --- |
| MVP writer auth | Supabase anonymous Auth | Exercises real user ownership and RLS without pretending phone or Apple Auth is complete |
| Post media | Public `post-media` bucket with owner-only writes | Posts are public by default while uploads and deletion remain scoped to the writer |
| Data writes | Transactional `create_post` and `update_post` functions | A post, its tags, and its visit cannot be partially saved |
| Deletion | Hard-delete the post and photo; retain the visit record | Provides literal CRUD while preserving the fact that the place was visited |
| Authorization | RLS on posts, post tags, visits, and storage objects | A visitor can update or delete only their own content |

## Map log source extension

The map now displays the user's own logs, public logs from accepted friends, and
Pind-authored starter logs. Every pin opens the log first and retains a direct
link to its Supabase-backed place record and the post composer.

- Actor: the same anonymous demo visitor
- Entry point: the Korea log map
- Expected outcome: the visitor can distinguish who a log came from and reuse
  the attached place information to write their own MyLog
- PRD coverage: G-04, J-07 step 4, FR-MAP-003/004/005/006/009,
  FR-SR-005, FR-PL-002, FR-FE-001, FR-SO-001/002/004/005, FR-JR-002

| Area | Decision | Reason |
| --- | --- | --- |
| Map source model | `mine`, `friend`, and `default` are explicit source values | Keeps filters and visual provenance unambiguous |
| Friend definition | Only an accepted, mutual `friendships` row qualifies | A random public post must not be presented as a friend's recommendation |
| Friend visibility | Only a friend's public posts appear; the owner still sees their own private logs | Preserves post privacy while keeping the personal map complete |
| Pind defaults | Editorial logs live in separate `editorial_logs` tables | Seed content is not disguised as user-generated content |
| Place source | All three log types reference the existing `places` record | The composer, map detail, and place detail share one source of truth |
| Demo fixture | Two accepted demo friends and eight published Pind picks are connected to the current test visitor | Makes the three-source flow directly testable before friend-management UI exists |

## Live place provider extension

The place picker now has a Google Maps search path. Selecting a result resolves a
durable internal `places.id`, after which the normal MyLog transaction, ownership
rules, friend visibility, and map-pin flow continue unchanged.

- PRD coverage: D-005, J-01, J-04 steps 1-3, FR-MAP-001/002/005/006/009,
  FR-SR-001, FR-PL-001/002, FR-PO-003/006/009, FR-API-001/002/003/004/005

| Area | Decision | Reason |
| --- | --- | --- |
| Place provider | Google Places API (New) | User-selected option 1 and provides real venue photos |
| Map provider | Google Maps SDK through `react-native-maps` | Google Places content is not mixed with a non-Google map |
| API boundary | Authenticated Supabase Edge Function | The Places Web Service key never ships in the mobile bundle |
| Durable data | Store only Google Place ID and Pind's internal ID | Google Place IDs are exempt from caching restrictions; provider content and photo references are not |
| Place hydration | Fetch name, address, coordinate, and photo on search/app load | Keeps displayed Google content fresh and avoids expired photo URLs in Postgres |
| Attribution | `Google Maps`, photo author, and source-photo links are rendered with provider content | Follows current Places display and photo attribution requirements |
| Failure mode | Existing demo catalog remains available if Google keys are absent | Local CRUD and map validation do not become blocked by external account setup |

## Place-first map and log-feed navigation

The accepted product structure is place-first rather than log-pin-first. The
main Map tab loads nearby Google food venues, renders one photo PIN per place,
and opens a scrollable place detail with live venue information and every Pind
log attached to that place. The sibling Logs tab renders the same logs as
post-style cards and keeps create, read, update, and delete in that feed.

- Actor: the same anonymous Fast MVP visitor
- Entry point: the main Map tab or its sibling Logs tab
- Expected outcome: a visitor can discover a real venue first, understand it,
  read community food experiences, and write their own log without changing
  product contexts
- PRD coverage: D-005, D-009, J-02, J-03, J-04, J-05,
  FR-MAP-001/004/005/006/009, FR-PL-001/002/005/006,
  FR-PV-001/005/006, FR-FE-001/002, FR-PO-001/003/009

| Area | Decision | Reason |
| --- | --- | --- |
| Map entity | One PIN per place, never one PIN per log | The map answers “where can I go?” while logs remain supporting content |
| Initial catalog | Google Nearby Search (New) for restaurants, cafes, bakeries, and dessert shops | Real venues are visible without requiring a search first |
| Detail loading | Base fields for map load; opening hours, phone, website, and editorial summary only after a PIN tap | Keeps the first map request smaller and defers higher-cost detail fields until intent is clear |
| Place detail | Venue information followed by every Pind log for the same internal place ID | External facts and community experience stay connected without mixing sources |
| Primary navigation | Persistent Map / create / Logs tab bar | Discovery and posting are sibling modes on one root page |
| Feed scope | Mine, accepted friends, and Pind editorial logs | Matches the map's trusted source model while keeping owner-only edit/delete controls |
| Provider persistence | Store only Google Place ID and Pind internal ID | Live Google fields remain fresh and are not cached in Postgres |

## Korea viewport, venue photos, and community menus

Moving the map now triggers a bounded Nearby Search for the visible area anywhere
in South Korea. The place sheet loads a larger Google photo gallery and an
available provider description. Because Google Places does not expose a reliable
structured restaurant menu or identify place photos as menu photos, the menu
section is derived from real Pind logs: each distinct dish name is paired with
the food photo uploaded in that log.

The global create actions open with no place selected. A writer must choose a
Google place explicitly; only a create action launched from a specific place
detail carries that place forward.

| Area | Decision | Reason |
| --- | --- | --- |
| Geographic scope | Current map viewport across South Korea | Avoids a one-time nationwide data load while supporting every Korean region |
| Viewport refresh | Query after map movement completes, capped at Google Nearby's 50 km radius | Keeps requests intentional and bounded |
| Place imagery | Hero plus up to five additional live Google place photos | Provides richer venue context while avoiding bulk photo requests for every map pin |
| Place description | Google editorial summary when present, otherwise a factual name/category/address/status description | AI place summaries are not available for Korean places and invented copy would be misleading |
| Menu source | Distinct menu names and food photos from Pind logs | Makes provenance explicit and never presents generic venue photos as a restaurant menu |
| Composer place | Empty by default, Google place search required | Removes accidental logs against a demo or unrelated preselected place |
| Map navigation | Native pinch zoom plus explicit zoom in/out and current-location controls | Keeps map movement discoverable and satisfies current-area exploration without making location permission mandatory |
| Location privacy | Request foreground access only after the location button is tapped; never persist the coordinate | Supports nearby discovery while preserving manual exploration after denial |

## Intentionally deferred

- Phone and Apple authentication
- Official restaurant menu feeds and prices
- Saved places and journeys
- Friend request/accept UI, follows, moderation, notifications, chatbot
- Server-side recommendation learning and analytics

## Stage boundary

This slice is **demo-ready**, not connected or pilot-ready. Supabase reads and
writes, Storage uploads, RLS ownership, Google Nearby/Place Details, and map
rendering are real in the current development project. Fresh environments still
require billing, the Places API (New), Maps SDK keys, and the server secret. Taste
preferences are local and production phone or Apple authentication is still
deferred. Friend relationships and logs use real tables and RLS, but the
accepted friends are current-device demo fixtures rather than a production
social onboarding flow.
