# austinmcnair.com

Personal portfolio + resource site for Austin McNair, MAT — SPED teacher on Chicago's South Side, senior digital designer and developer.

## Stack

- **[Astro](https://astro.build)** with MDX for article content and Sitemap integration.
- Static output (SSG). No serverless, no database, no auth. Everything renders to HTML/CSS at build time.
- **Fonts:** Newsreader (serif · editorial + article body) + Inter (UI + metadata) + Chakra Petch (wordmark + section eyebrows). Loaded from Google Fonts with `display=swap`.
- **Palette:** Console mode (deep navy) is the default. Paper (warm off-white light mode) is a planned follow-up toggle.
- **Deployment target:** Vercel.

## Source of truth

The brand + style guide lives outside this repo at:

```
~/Desktop/austinmcnair.com/AUSTINMCNAIR_BRAND_AND_STYLE_GUIDE.md
```

Current version: **v5 (2026-07-18)**. When the guide and the site disagree, update the guide first, then match the site to it. Do not silently drift.

## Project structure

```
src/
├── components/       # ProductShot, ArticleCard, ProjectRow, ContactCard, Nav, Footer
├── content/
│   ├── config.ts     # Content collection schema
│   └── writing/      # .mdx article files
├── layouts/
│   └── Layout.astro  # Sitewide shell (head, nav, footer, font preloads)
├── pages/
│   ├── index.astro   # Homepage — Case Study Hero template (§5.1 v5)
│   └── writing/
│       └── [...slug].astro  # Dynamic article route
└── styles/
    └── global.css    # Tokens + base + reduced-motion reset
public/
├── favicon.svg
└── img/
    ├── pd101-mission-control.png
    └── pd101-lessons.png
```

## Local dev

```sh
npm install
npm run dev       # http://localhost:4321
npm run build     # ./dist output
npm run preview   # preview the production build
```

## Content: adding an article

1. Create `src/content/writing/<slug>.mdx`.
2. Frontmatter fields (see `src/content/config.ts` for the schema):
   ```yaml
   ---
   title: 'The title'
   dek: 'One-sentence summary in Austin voice.'
   category: 'Framework' | 'Case Study' | 'Field Notes'
   date: 2026-07-15
   readTime: '14 min'
   draft: false
   ---
   ```
3. `draft: true` posts render in dev but are excluded from the production build.
4. Add the piece to the `articles` array in `src/pages/index.astro` when you want it surfaced on the homepage.

## Todos / placeholders

- Article deks in `src/pages/index.astro` are placeholders. Real drafts pending.
- Third homepage outcome stat (`6→8`) is a placeholder — confirm the metric.
- LinkedIn URL and Résumé PDF in `ContactCard` are `href="#"` with `data-todo` attributes.
- `/work/policydebate101` full case-study page not yet built (linked from homepage).
- Paper (light mode) not implemented yet — follow-up.
- Real `og:image` — currently reuses the Mission Control screenshot; a dedicated 1200×630 OG asset would be better.
