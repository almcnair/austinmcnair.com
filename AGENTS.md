# AGENTS.md — austinmcnair.com

Notes for AI collaborators working in this repo.

## What this repo is

The real, production-bound site for **austinmcnair.com**. Astro static build, deployed to Vercel. It is not the mocks folder — mocks live at `~/Desktop/austinmcnair.com/mockups-v4/`.

## Source of truth

The brand + style guide is canonical. It lives at:

```
~/Desktop/austinmcnair.com/AUSTINMCNAIR_BRAND_AND_STYLE_GUIDE.md
```

**Current version:** v5 (2026-07-18). The home template is **Case Study Hero** (§5.1) with PD101 in the two-column hero and the case-study body directly below. Section order is locked in §5.6.

**If a design change conflicts with the guide:** update the guide first (bump the version, write a changelog entry at the top), then make the site match. Never drift silently.

## Sibling context

- **PD101** is Austin's flagship product: `~/dev/policydebate101-app/` (Next.js on Vercel). This site links out to it and hosts its case study.
- **Older mock repo:** `~/dev/austinmcnair-mocks/` — pre-v5 experiments. Reference only; do not commit to it as the "real" site.
- Austin's mocks folder: `~/Desktop/austinmcnair.com/mockups-v4/` — the three v5 candidate mocks. Mock 01 (Case Study Hero) is the one this repo implements.

## Voice and tone

- First person, Austin's voice. Warm, plainspoken, specific.
- **Never** Support Commander persona, Cadet/Debater vocabulary, or PD101 space-academy narration on this site. That vocabulary is scoped to the PD101 case study section only (§0.2, §4.7).
- No hype ("game-changing," "empowering," "reach out"). See §3.4 banned phrases.

## Palette + type — do not free-style

- Console mode: `--void #090C1F`, `--panel #101636`, `--line #232852`, `--text #F1F4FF`, `--text-dim #A8B2D8`, `--text-faint #6A7BA8`.
- Accents: `--cyan #22D3EE` (only functional accent), `--warm #EC5D9E` (editorial category tags only, never interactive).
- Type: Newsreader (serif · editorial/article body), Inter (UI/metadata), Chakra Petch (wordmark + section eyebrows only).
- Body minimum: **18px, no exceptions** (§4.3).

## Accessibility floor — non-negotiable

WCAG 2.1 AA minimum (§0.6). Every change should preserve:
- Semantic HTML (real `<article>`, `<nav>`, `<main>`, heading order)
- Visible focus rings on every interactive element
- Alt text on every content image; `alt=""` on decorative
- Reduced-motion respected (the global reset in `src/styles/global.css` covers most of this — do not remove it)
- 4.5:1 contrast for body, 3:1 for large text

## Placeholders currently in the repo

Search for `TODO(austin)` in the source. Known placeholders:
- Homepage article deks (`src/pages/index.astro`)
- Third outcome stat (`6→8`)
- LinkedIn URL and Résumé PDF href in `ContactCard`
- Draft article at `src/content/writing/missions.mdx` (marked `draft: true`)

## Build / verify

```sh
npm run build   # must succeed with no errors before committing
npm run preview # smoke-test locally
```

If you touch styling, verify at desktop (1280px+), tablet (~820px), and mobile (~400px) widths at minimum.
