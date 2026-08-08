# Andrew — Leo Eclipse Reading (2026-08-12)

Client-facing reading page. Not linked from anywhere on the site; discoverable only by direct URL.

- **URL when deployed:** https://austinmcnair.com/r/andrew-2026-08-leo-eclipse/
- **`noindex, nofollow`** meta on the page.
- **`Disallow: /r/`** in `public/robots.txt`.
- **Excluded from sitemap** via `astro.config.mjs` filter.

## Before pushing to production

⚠️ **The "Download PDF" button on the reading page links to `./andrew-2026-08-leo-eclipse.pdf` in this folder.**

**Drop the client-facing PDF here** before deploy:

```
src/pages/r/andrew-2026-08-leo-eclipse/andrew-2026-08-leo-eclipse.pdf
```

If you push without it, the button 404s (page still renders fine, just the download won't work).

## Files

- `index.html` — the reading (copy of `~/Desktop/Astrology/andrew-2026-08-12-leo-eclipse.html` + PDF button + noindex).
- `andrew-2026-08-leo-eclipse.pdf` — client-facing PDF (Austin adds later).

## Pattern for future readings

`src/pages/r/{firstname}-{YYYY}-{MM}-{event-slug}/`
- `index.html` (copy of the desktop working file, add noindex meta + PDF button)
- `{same-slug}.pdf`
- `README.md`
