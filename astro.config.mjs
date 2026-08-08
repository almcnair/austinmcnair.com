// @ts-check
import { defineConfig } from 'astro/config';

import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://austinmcnair.com',
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
