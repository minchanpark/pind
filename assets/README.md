# Assets

Folders follow the screen that uses them. Vectors are the original Figma exports (file `AepN5S4XiejtlWS52Q7Arg`) at their SVG root size; simple shapes (circles, ellipses, glass pills) are drawn in Flutter instead of shipped as files.

| Folder | Screen · part | Files |
| --- | --- | --- |
| `login/` | 로그인 (`531:18341`) | `pin.svg` 58×78.1 brand PIN · `route_path.png` 393×281 dashed route (PNG export of vector `531:18360`; the SVG renderers spaced the dashes differently) |
| `onboarding/cuisines/` | 온보딩 · 좋아하는 음식 카드 | one photo per `Cuisine` value, named after it (`korean.png` … `dessert.png`; `bakery`, `bar` have none) |
| `explore/` | 지도 · 상단 검색창 | `search_icon.svg` 15.5 · `filter_icon.svg` 14.5 |
| `place_detail/` | 가게 상세 시트 (`524:30239`) | `close_icon.svg` 38 · `location_icon.svg` 13.4 · `save_icon.svg` 13.5 · `share_icon.svg` 13.5 · `directions_icon.svg` 15.5 |
| `post_composer/` | 게시물 작성 (`531:18182`, `531:18260`) | `close_icon.svg` 20.6 · `camera_icon.svg` 23 (no photos yet) · `add_photo_icon.svg` 20×17.9 · rating stars `star_{taste,portion,ambience}.svg` 25.6×24.1 and `star_{portion,ambience}_empty.svg` 19.6×18.1 |
| `navigation/` | 하단 내비게이션 바 | `discover_icon.svg` 26 · `map_icon.svg` 23 · `compose_icon.svg` 31 · `profile_icon.svg` 24; shipped in inactive grey `#B0B0B0`, the selected tab is tinted black in code |
| `preview/` | QA only, never shown to users | `place_detail_photo_{1,2,3}.png`, `place_detail_avatar.png` for `lib/view/preview/detail_preview.dart`; `post_photo_{1,2}.png` for the post tests |
| `app_icon.png` | 앱 아이콘 원본 (not bundled) | flat lime `#F4FF5A`; iOS sizes in `ios/Runner/Assets.xcassets/AppIcon.appiconset` are generated from it as opaque full squares (iOS applies its own corner mask; the store rejects alpha). Regenerate them when this file changes. |
| `fonts/` | 로그인 브랜드 문구 | Braah One, Bayon (OFL licenses alongside) |

## Rules

- Keep SVG root width/height; layout slots place the root, the vector is not redrawn. Exported SVG filters are unsupported by `flutter_svg`, so glass blur, rims and shadows are rendered by `PindGlass`.
- Onboarding circles (map bubbles, check marks, avatar backdrop and ✚ button, location dot/halo, parks) are `SetupCircle` / `DecoratedBox` in `lib/view/onboarding/registration_components.dart` and `location_permission_screen.dart`, not assets.
- User and place photos come from the API. Nothing in `preview/` may be inserted into production data.
- Tests check each remaining file's root size and rendered size: `registration_assets_test.dart`, `post_assets_test.dart`, `place_detail_test.dart`, `navigation_test.dart`.
