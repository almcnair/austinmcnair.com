# RESUME HERE — austinmcnair.com

_Paused Sat 2026-07-18 · 1:08 PM CDT_

## Where we are

- **Brand guide bumped v4 → v5** at `~/Desktop/austinmcnair.com/AUSTINMCNAIR_BRAND_AND_STYLE_GUIDE.md`. Homepage template is now **Case Study Hero** (§5.1). Section order rewritten in §5.6. Audience reordered in §2 to put hiring managers / EdTech founders / school admins co-primary; teachers first-class secondary.
- **Real repo scaffolded** here at `~/dev/austinmcnair.com/`. Astro 7 static + MDX + sitemap. Committed on `main`, no remote yet.
- **Homepage** (`src/pages/index.astro`) matches Mock 01 from `~/Desktop/austinmcnair.com/mockups-v4/mock-1-case-study-hero.html`, with both real PD101 screenshots wired in.
- **Build verified clean:** `npm run build` succeeds, 1 page (the `missions.mdx` draft is correctly filtered from prod).

## Sanity check when you return

```sh
cd ~/dev/austinmcnair.com
npm run dev       # http://localhost:4321
# then open ~/Desktop/austinmcnair.com/mockups-v4/index.html to compare against the mock
```

## Open decisions (pick when you come back)

1. **Ship path — GitHub + Vercel?**
   - Push repo to a new GitHub repo (probably `austinmcnair/austinmcnair.com`)
   - Connect to Vercel (Austin already has a Vercel account from PD101)
   - Point the `austinmcnair.com` DNS at Vercel

2. **Placeholder cleanup** (grep the repo for `TODO(austin)`)
   - Real article deks — 4 homepage articles have plausible placeholder deks
   - Third outcome stat (`6→8`) — invented, needs a real metric
   - LinkedIn URL in `src/components/ContactCard.astro`
   - Résumé PDF (upload → `public/austin-mcnair-resume.pdf` and update the href)

3. **Next feature** — pick one:
   - Build the full `/work/policydebate101` case study page (linked from homepage but 404 right now)
   - Write the first real article (replace `src/content/writing/missions.mdx`, flip `draft: false`)
   - Add Paper (light mode) palette + toggle
   - Dedicated 1200×630 OG image

## What NOT to do

- Don't edit `~/dev/austinmcnair-mocks/` — that's the archived Option-C repo from July 8. It's preserved on purpose. The real site is here.
- Don't drift from the guide silently. If a design change conflicts with `~/Desktop/austinmcnair.com/AUSTINMCNAIR_BRAND_AND_STYLE_GUIDE.md`, bump the guide first (v5 → v6, add a changelog block at the top), then match the site to it.
- Astro 7 gotcha: content collection config lives at `src/content.config.ts` (root of src, NOT `src/content/config.ts`). Uses `loader: glob(...)` from `astro/loaders`.

## Files that matter

```
Repo:      ~/dev/austinmcnair.com/
Guide:     ~/Desktop/austinmcnair.com/AUSTINMCNAIR_BRAND_AND_STYLE_GUIDE.md   (v5)
Mocks:     ~/Desktop/austinmcnair.com/mockups-v4/                             (Mock 01 is the chosen one)
Old repo:  ~/dev/austinmcnair-mocks/                                          (archive, do not touch)
```
