# Figma asset provenance

Source: Pind Figma file `AepN5S4XiejtlWS52Q7Arg`, development page `468:15492`, sixth design section `531:17779`, cuisine screen `531:18416`. Downloaded through Figma MCP design-context asset links on 2026-09-26. These are source design images, not screenshots of complete UI.

| File | Cuisine / use |
| --- | --- |
| 838d7.png | Korean |
| b887a.png | BBQ |
| 319be.png | Soup |
| eb159.png | Noodles |
| 230fd.png | Street food |
| c1df7.png | Japanese |
| 8aa62.png | Sushi |
| 56250.png | Chinese |
| 92aad.png | Western |
| 09c52.png | Asian |
| 27b11.png | Chicken |
| fc2b8.png | Dessert |
| 808cb.svg | Yellow selection ellipse |

The SVG includes HTML backdrop/filter effects unsupported by flutter_svg; the visible vector ellipse is rendered, but its exported blur is not an exact reproduction. Bakery/bar remain text cards because this source export did not include corresponding photo assets. Confirm source image usage rights before production distribution.
# Place detail assets — 2026-09-27

Source file `AepN5S4XiejtlWS52Q7Arg`: header `524:30239`, actions `524:30207`, gallery `524:30280`.

- `detail_close.svg`: `1cb0d.svg`, 38×38. Exported HTML filter is unsupported by flutter_svg; original vector is unchanged, surrounding glass is rendered in Flutter.
- `detail_location.svg`: `9ef12.svg`, 13.3989×13.3989.
- `detail_save.svg`: `50fd6.svg`, 13.4603×13.4603.
- `detail_share.svg`: `2a906.svg`, 13.542×13.542.
- `detail_directions.svg`: `ff68b.svg`, 15.4546×15.4546.
- `detail_fixture_photo_{1,2,3}.png`: `ffde6`, `d95dd`, `33635`. Dynamic gallery slots in production; original Figma photos in local QA only.
- `detail_fixture_avatar_{1,2}.png`: `75fed`, `ef1b3`. Local QA imagery only; production avatars come from visible friend profiles.

No temporary Figma URLs remain in runtime code. `place_detail_test.dart` checks all five static icon files and rendered dimensions. Native screenshots cover collapsed/expanded/no-friend states. The labeled local preview never replaces failed live requests with fixtures.

# Navigation assets — 2026-09-26

`nav_*.svg` (12 files) are original vectors from Figma file `AepN5S4XiejtlWS52Q7Arg`:

- Map selected: `531:17799` → map `16df0`, discover `a6d7f`/`b39d3`, profile `e50c6`/`d4d3c`, compose `20761`/`daadd`.
- Discover selected: `531:19123` → map `c2745`, discover `6e63f`/`ded3b`.
- Profile selected: `531:20050` → profile `229f5`/`057bd`.

Original files, colors, root dimensions and vector paths are unmodified. Each SVG occupies its original slot inside a 30.0458pt icon frame in `PindNavigationBar`. No network asset URLs remain in runtime code. Three golden tests and root-size/slot checks cover the active and inactive states. The floating 273×58 container is rendered natively with blur, border and shadow; the Figma screenshot is a comparison target, not an app asset.
