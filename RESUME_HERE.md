# RESUME HERE — austinmcnair.com

_Paused Sat 2026-07-18 · 10:30 PM CDT_

## Where we are

**THE SITE IS LIVE.** 🎉

- **Production URLs:**
  - `https://austinmcnair.com` (apex)
  - `https://www.austinmcnair.com`
  - `https://austinmcnaircom.vercel.app` (Vercel default)
- **Repo:** `https://github.com/almcnair/austinmcnair.com` (public, `main` branch, up to date)
- **Vercel project:** `austinmcnair.com` under team `policy-debate-101`
- **DNS:** GoDaddy managing DNS, apex A → `76.76.21.21`, www CNAME → `cname.vercel-dns.com`
- **First article shipped:** `/writing/why-i-built-pd101` (Framework, 4 min, published 2026-07-18)

## Pending redesign — DO THIS NEXT

Austin critiqued the current article page (see screenshots from the 2026-07-18 evening session) and correctly flagged it as visually flat and off-brand. **Full redesign plan already agreed upon** — Austin just wants to answer two questions before I execute:

### Question A — screenshots

Ship the redesign now with the two existing PD101 screenshots + inline `[SCREENSHOT NEEDED]` placeholders in three spots, OR wait for Austin to paste new screenshots first?

The three additional screenshots the article needs:

1. **A "bite-sized mission" screen** — for the scheduling / self-paced point
2. **An interactive graphic-organizer screen** — for the cognitive point
3. **A culturally-responsive mission scenario screen** — for the identity point

### Question B — /writing index layout

Simple chronological list, or filterable grid by category (Framework / Case Study / Field Notes)?

## What the redesign will do (already scoped)

1. **New IA:** Build `/writing` as a real writing index page. Change nav "Writing" from `/#writing` scroll target to `/writing` proper page. Articles become browsable, addressable, and have a home.

2. **Copy fix:** "already knows" → "already shows" in the H2.

3. **Article page redesign — apply v5 brand system:**
   - Category chip as a proper pill (pink `--warm` fill, not just text)
   - Cyan `--cyan` pull-quote block for the thesis line
   - Stat callouts in bold cyan for research numbers (68%, 0.66 GPA, 18%) — matches homepage outcome-stat treatment
   - **Three-barrier section as a color-coded 3-card grid:** scheduling (cyan), cognitive (warm/pink), identity (green `--ok`). Each barrier gets its own visual identity — this is where "color differentiates meaning" earns its keep.
   - Eyebrow-line treatment on H2s to match homepage section headers
   - "See it in production" section wiring in real PD101 screenshots

4. **Guide impact:** Stay inside v5 palette if possible. If new tokens/components are introduced, bump guide v5 → v6 with a changelog block first.

## Known TODO(austin) placeholders still in the repo

- Homepage article deks — 3 remaining pieces are still placeholder deks (curriculum-as-product, one-idea-per-slide, teacher-moves). Featured slot now has real content.
- Third outcome stat `6→8` — still invented
- LinkedIn URL in ContactCard
- Résumé PDF (upload → `public/austin-mcnair-resume.pdf` and update the href)
- `/work/policydebate101` full case study page not yet built (linked from homepage but currently 404s)
- Missions Framework essay (`src/content/writing/missions.mdx`) still `draft: true` — Austin will write later
- Placeholder articles referenced from homepage (`/writing/teacher-moves`, `/writing/one-idea-per-slide`, `/writing/curriculum-as-product`) don't exist yet — dead links until written
- Paper (light mode) toggle deferred
- Dedicated 1200×630 OG image (currently reuses Mission Control screenshot)
- Article footnote citation URLs (Mezuk 2011, Ko & Mezuk 2021) — need actual DOI/PDF links

## Ship gotchas learned this session (don't repeat)

1. **Vercel SSO / Deployment Protection is ON by default at the team level** for `policy-debate-101`. Kill it via REST API: `PATCH /v9/projects/{id}?teamId=…` with `{"ssoProtection": null}`. Otherwise new domains 302 to Vercel SSO login.
2. **`vercel domains add` at the account level ≠ project alias.** Also run `vercel alias set <deployment-url> <domain>` to bind the domain to the project's production deployment. Both apex and www need this separately — they don't auto-mirror.
3. **GoDaddy Airo / Domain Connect** aggressively auto-manages DNS. Disconnect Airo from the domain settings before ANY DNS work, or GoDaddy will lock the trash icons on the A records.
4. **Local macOS DNS cache** can pin to old A records for a long time. `sudo killall -HUP mDNSResponder` to flush. Public resolvers (Google 8.8.8.8, Cloudflare 1.1.1.1) update within minutes.

## Sanity check when you return

```sh
cd ~/dev/austinmcnair.com
git pull
npm run dev       # http://localhost:4321
```

Then reread this file and check for Austin's answers to Question A and Question B above.

## What NOT to do

- Don't edit `~/dev/austinmcnair-mocks/` — archived Option-C repo from July 8. Preserved on purpose. Real site is here.
- Don't drift from the guide silently. If a design change conflicts with `~/Desktop/austinmcnair.com/AUSTINMCNAIR_BRAND_AND_STYLE_GUIDE.md`, bump the guide first (v5 → v6, add a changelog block at the top), then match the site to it.
- Don't push directly to production without a build. `vercel --prod --yes` is fine; skipping the local `npm run build` sanity check is not.
- Astro 7 gotcha: content collection config lives at `src/content.config.ts` (root of src, NOT `src/content/config.ts`). Uses `loader: glob(...)` from `astro/loaders`.

## Files that matter

```
Repo:      ~/dev/austinmcnair.com/
Guide:     ~/Desktop/austinmcnair.com/AUSTINMCNAIR_BRAND_AND_STYLE_GUIDE.md   (v5)
Mocks:     ~/Desktop/austinmcnair.com/mockups-v4/                             (Mock 01 is the chosen one)
Old repo:  ~/dev/austinmcnair-mocks/                                          (archive, do not touch)
```
