# AGENTS.md — austinmcnair.com

Notes for AI collaborators working in this repo.

## What this repo is

The real, production-bound site for **austinmcnair.com**. Astro static build, deployed to Vercel. It is not the mocks folder — mocks live at `~/Desktop/austinmcnair.com/mockups-v4/`.

## Source of truth

The brand + style guide is canonical. It lives at:

```
~/Desktop/austinmcnair.com/AUSTINMCNAIR_BRAND_AND_STYLE_GUIDE.md
```

**Current version:** v6 (2026-07-29). The home template is **Case Study Hero** (§5.1) with PD101 in the two-column hero and the case-study body directly below. Section order is locked in §5.6.

**If a design change conflicts with the guide:** update the guide first (bump the version, write a changelog entry at the top), then make the site match. Never drift silently.

## Copy discipline (§3.7 of the brand guide) — READ THIS BEFORE WRITING PROSE

Every descriptive claim on this site must trace back to one of two things:

1. **Austin told me it's true**, in a session I can point to.
2. **A source document says it's true** — this AGENTS.md, the brand guide, a confirmed case-study draft, a résumé, or a shipped feature I can verify by reading the code.

If I can't point to either, **I don't write it.** Not on the site, not in a mockup, not in "placeholder" copy that ships to production because nobody swapped it out.

**This rule applies in both directions:**

- **Adding:** no invented stats, no fabricated outcomes, no aspirational status labels ("Draft in Figma," "In beta," "Coming soon" when nothing's actually coming), no product taglines Austin hasn't approved.
- **Keeping:** when editing a section that already has prose, treat every existing sentence as suspect. Inherited scaffold copy is a common source of drift — it gets written once as filler, then gets "preserved" through refactors because nobody wanted to touch it. If I'm about to keep a sentence, I need to be able to say why it's true. If I can't, I flag it to Austin instead of silently shipping it forward.

**Placeholder-hunt on entry.** The first time I touch any section in a session, I scan the *whole section* for `TODO(austin)`, invented stats, placeholder deks, and inherited scaffold copy. I flag those to Austin *before* I make my actual change — not after.

**Pre-commit checkpoint.** Before I say "ready to commit and push," I list every piece of prose I changed *or preserved* in this session, one line each. Austin gets to veto anything that snuck in.

Background: this rule was locked in 2026-07-29 after "Draft in Figma" survived from an old scaffold into a live page. Designed to make that failure mode structurally impossible to repeat.

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

Search for `TODO(austin)` in the source. Known placeholders (as of 2026-07-29):
- Homepage article deks (`src/pages/index.astro`) — flag before shipping
- Third outcome stat slot on the PD101 case-study section — `6→8` was removed as unconfirmed; do **not** refill with a placeholder (per §3.7). Leave the slot out until a real, Austin-confirmed number lands.
- LinkedIn URL and Résumé PDF href in `ContactCard`
- Draft article at `src/content/writing/missions.mdx` (marked `draft: true`) — the file is a scaffold; the real piece has not been written yet

When you land in any of these files for a different reason, do the placeholder-hunt (above) and surface what you find.

## Build / verify

```sh
npm run build   # must succeed with no errors before committing
npm run preview # smoke-test locally
```

If you touch styling, verify at desktop (1280px+), tablet (~820px), and mobile (~400px) widths at minimum.
