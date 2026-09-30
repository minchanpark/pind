# Figma asset provenance

## Explore search bar — 2026-09-28

Source: Pind Figma file `AepN5S4XiejtlWS52Q7Arg`, search bar `524:28096`.

| Local file | Original export | Root size | Design slot |
| --- | --- | --- | --- |
| `explore_search.svg` | `80960.svg` | 15.4927×15.4927 | Search icon `524:28097` |
| `explore_filter.svg` | `48da5.svg` | 14.457×14.457 | Filter button icon `524:28103` |

Both SVGs are unmodified original exports. The search bar renders their original sizes with native background blur, border, outer shadows and inset highlights. The Figma screenshot is a comparison reference only.

## Onboarding assets — 2026-09-28

Source file `AepN5S4XiejtlWS52Q7Arg`: login `531:18341`, country `531:18621`, basic information `531:20155`, handle `531:18681`, location permission `531:18369`. All files below are original downloads, including transparent SVG export insets. Flutter uses local asset paths and retains the exported root dimensions.

| Original file | Root size | Screen slot |
| --- | --- | --- |
| `login_path.png` | 393×281 | Login dashed path; original asset export of vector node `531:18360`, already rotated |
| `ca1af.svg` | 280.657×392.203 | SVG source export retained for provenance; runtime uses the matching PNG export |
| `a0e89.svg` | 58×78.1015 | Login PIN |
| `808cb.svg` (existing) | 34×34 | Country selection indicator |
| `22e3f.svg` | 96×96 | Handle avatar backdrop |
| `37ea8.svg` | 64×64 | Handle avatar add control (32px circle plus export insets) |
| `d43d2.svg` | 170×140 | Location illustration outer ellipse |
| `9d337.svg` | 150×120 | Location illustration inner ellipse |
| `ae7d9.svg` | 32×32 | Location center dot |
| `33c00.svg` | 120×120 | Location halo |
| `e7fea.svg` | 88×88 | Coffee bubble |
| `f61aa.svg` | 72×72 | Ramen and steak bubbles |
| `fe8cf.svg` | 68×68 | Cake bubble |
| `dce83.svg` | 72×72 | Nearby benefit bubble |
| `457fb.svg` | 72×72 | Friend and ranking benefit bubbles |

Exported HTML `foreignObject` and SVG filter effects are unsupported by flutter_svg. `setupAsset` adds native backdrop blur/shadows behind the unchanged vector at the original circle inset. Illustration emoji remain native text, as in the design context. System status bar exports are not app artwork; the OS supplies those controls.

The path's SVG export produced different dash spacing from the Figma design when checked with both Flutter SVG renderers. The visible path uses the unmodified PNG returned by Figma `download_assets` for the individual vector node, at its original 393×281 size. This is an artwork asset export, not a whole-screen screenshot. No extra renderer dependency was retained.

Brand fonts are bundled under `assets/fonts`: Braah One from the [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/braahone), Bayon from the [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/bayon), each with its original OFL license. These families apply to the login artwork only.

`test/registration_assets_test.dart` checks nonempty original files, XML/PNG root sizes, every screen slot and rendered image/vector root size. The eight `artifacts/ios/onboarding-qa-*.png` captures document native visual review; screenshots are not runtime assets.

## Existing cuisine assets — 2026-09-26

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


# Post composer and map chips — 2026-09-28

Source file `AepN5S4XiejtlWS52Q7Arg`: composer `531:18182`, populated composer `531:18260`, all chip `542:22927`, category chip `542:22930`.

| Local asset | Figma export | Original SVG root |
| --- | --- | --- |
| post_close.svg | 2d5f1.svg | 20.6096 × 20.6096 |
| post_camera.svg | ac447.svg | 22.9817 × 22.9817 |
| post_add.svg | 9959e.svg | 20 × 17.8653 |
| post_taste_star.svg | b6360.svg | 25.6324 × 24.1341 |
| post_portion_star.svg | f43fe.svg | 25.6324 × 24.1341 |
| post_portion_star_empty.svg | ce2ab.svg | 19.6324 × 18.1341 |
| post_ambience_star.svg | c6122.svg | 25.6324 × 24.1341 |
| post_ambience_star_empty.svg | 561b5.svg | 19.6324 × 18.1341 |

SVGs remain unchanged. Stars use 24 × 23 logical slots with their original SVG extents and offsets. Exported SVG filter effects are unsupported by flutter_svg; glass blur and inset highlights are rendered natively. Gray unrated stars follow the source text treatment. `post_assets_test.dart` verifies every visible SVG root and rendered size.

`post_fixture_1.png` (92ec1.png) and `post_fixture_2.png` (22fa0.png) are original Figma QA fixtures. Production composition uses photos selected from the user's device; Figma restaurant names and images are not inserted into production posts.

Native screenshots: `artifacts/ios/post-composer-{empty,filled,filled-bottom}.png` and `artifacts/ios/map-filter-chips.png`. The 874px device scrolls the 1079px source composition; footer buttons remain visible while the form scrolls.
