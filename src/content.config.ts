import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const writing = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/writing' }),
  schema: z.object({
    title: z.string(),
    /** Optional HTML variant of the title used for the article <h1>. Allows
     *  inline <em> emphasis (rendered as italic Signal Cyan) to match the
     *  homepage hero pattern. Plain `title` is still used for <title>, OG,
     *  and listing views. */
    titleHtml: z.string().optional(),
    dek: z.string(),
    category: z.enum(['Framework', 'Case Study', 'Field Notes']),
    date: z.date(),
    readTime: z.string(),
    draft: z.boolean().default(false),
    ogImage: z.string().optional(),
  }),
});

export const collections = { writing };
