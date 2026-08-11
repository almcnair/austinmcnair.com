// @ts-check
import { defineConfig } from 'astro/config';

import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import vercel from '@astrojs/vercel';

// https://astro.build/config
export default defineConfig({
  site: 'https://austinmcnair.com',
  // Hybrid: all pages/routes are prerendered by default, and specific
  // API routes opt into server rendering with `export const prerender = false`.
  // Keeps the whole site static except the Jeopardy generate endpoint.
  output: 'static',
  adapter: vercel(),
  integrations: [
    mdx(),
    sitemap({
      // Exclude private client reading pages from the sitemap.
      filter: (page) => !page.includes('/r/'),
    }),
  ],
  build: {
    inlineStylesheets: 'auto',
  },
});
