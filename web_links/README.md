# Profile link host

Production: https://pind-profile-links.vercel.app
Vercel project: `pind-profile-links`, NEWDAWN scope `newdawn1`.

This domain is the default `AppConfig.linkHost` and `LINK_HOST` in both
config files. iOS Associated Domains and Android verified HTTPS intents
use the same host. The old `pind.app` domain is no longer used for HTTPS
profile links; `com.pind.app://` remains the existing custom scheme for
OAuth callbacks and the web page's "앱에서 열기" link.

Deploy this folder as the site root. `vercel.json` provides JSON headers
for AASA and rewrites `/@handle` and `/u/<id>` to `index.html`.

```sh
pind_link_deploy_dir="$(mktemp -d)"
cp web_links/index.html web_links/vercel.json "$pind_link_deploy_dir/"
cp -R web_links/.well-known "$pind_link_deploy_dir/"
npx vercel deploy "$pind_link_deploy_dir" --project pind-profile-links --scope newdawn1 --prod --yes
```

Use the standalone static folder so unrelated repository commit-author
metadata is not attached to a direct upload. The deployed runtime needs
only `index.html`, `vercel.json` and `.well-known/`.

## Verified setup

- Apple Developer: JUNHWAN LEE (`ZNNY3727TQ`), App ID `com.newdawn.pind`
  registered with Associated Domains enabled. iOS build settings and
  AASA use this identifier. Android retains package `com.pind.app`.
- Kakao Developers: Pind app `1589931`; iOS `com.newdawn.pind`, Android
  `com.pind.app`, and local debug key hash saved and verified. The chosen
  production domain is registered as the default product-link domain;
  the old `pind.app` product-link domain was removed.
- Native key is in ignored `config/local.json`; both native projects
  register the Kakao sharing callback scheme.
- Anonymous HTTPS GETs returned 200 without redirects for AASA,
  assetlinks and `/@pind_junhwan`. AASA returned `application/json` and
  `ZNNY3727TQ.com.newdawn.pind`; assetlinks returned `com.pind.app`.
- Chrome displayed the correct profile fallback page.
- Independently decoded the rendered QR with its center P logo to exactly
  `https://pind-profile-links.vercel.app/@pind_junhwan`. Evidence image:
  `artifacts/verification/pind-vercel-profile-qr.png`.
- Flutter: 157 tests passed and analysis reported no issues after the
  chosen host was applied.

## Remaining release checks

- `assetlinks.json` lists only the local debug key. The project still signs
  Android release builds with the debug key; add the real release and
  Play App Signing SHA-256 fingerprints before shipping. Accessible
  active Google Play account `newdawn` currently has SOI only, so Pind's
  Play App Signing fingerprint is not yet available.
- Ensure the iOS Maps API key restrictions permit `com.newdawn.pind`.
- The App Store URL in `index.html` is still a TODO. The Play URL works
  once Pind is published under `com.pind.app`.
- Actual-device camera scanning, installed-app universal/app links,
  cold starts, and onboarding link continuation remain unverified.
