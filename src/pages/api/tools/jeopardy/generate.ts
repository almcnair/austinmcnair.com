import type { APIRoute } from 'astro';
import Anthropic from '@anthropic-ai/sdk';
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

// This route MUST be server-rendered.
export const prerender = false;

// -----------------------------------------------------------------------------
// Env
// -----------------------------------------------------------------------------
// Required in Vercel env:
//   ANTHROPIC_API_KEY
//   UPSTASH_REDIS_REST_URL
//   UPSTASH_REDIS_REST_TOKEN
// The rate-limit block soft-fails open if Upstash env vars are missing, so a
// misconfigured deploy still works but is unprotected. Log warnings loudly.

const HAIKU_MODEL = 'claude-haiku-4-5';

const POINT_LEVELS = [200, 400, 600, 800, 1000];
const CATEGORY_COUNT = 5;

// -----------------------------------------------------------------------------
// Rate limit: 15 requests / IP / 24h.
// -----------------------------------------------------------------------------
let ratelimit: Ratelimit | null = null;
function getRatelimit(): Ratelimit | null {
  if (ratelimit) return ratelimit;
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) {
    console.warn('[jeopardy/generate] Upstash env vars missing — rate limit disabled');
    return null;
  }
  const redis = new Redis({ url, token });
  ratelimit = new Ratelimit({
    redis,
    limiter: Ratelimit.slidingWindow(15, '24 h'),
    analytics: false,
    prefix: 'ratelimit:jeopardy-generate',
  });
  return ratelimit;
}

function getClientIp(request: Request): string {
  // Vercel forwards the client IP in x-forwarded-for (comma-separated when
  // multiple proxies). x-real-ip is a fallback.
  const xff = request.headers.get('x-forwarded-for');
  if (xff) return xff.split(',')[0].trim();
  const xri = request.headers.get('x-real-ip');
  if (xri) return xri.trim();
  return 'unknown';
}

// -----------------------------------------------------------------------------
// System prompt
// -----------------------------------------------------------------------------
const SYSTEM_PROMPT = `You are helping a classroom teacher build a Jeopardy review game from a list of questions and answers they have already written.

Your job:
1. Read the pasted list.
2. Cluster the items into exactly 5 categories with exactly 5 clues each (25 total).
3. Order the 5 clues in each category by difficulty, easiest first, so they map cleanly to Jeopardy's $200 → $400 → $600 → $800 → $1000 point ladder.
4. Write short, clear category names in ALL CAPS (Jeopardy convention). Keep them short — 1 to 3 words.
5. Keep the teacher's original phrasing when it's already good. Do not rewrite content the teacher wrote unless it's genuinely unclear.
6. Phrase clues in Jeopardy answer-form only when the teacher already did or when it's trivially natural. If the teacher wrote plain questions, leave them as plain questions — do not force "This ___ is ___" phrasing.
7. Do NOT invent facts. If the teacher gave you 30 items, cluster the best 25. If they gave you 18, fill 18 and leave the remaining slots as empty strings — do not fabricate clues to fill space.
8. Do NOT set any Daily Double. The teacher will pick that themselves.

Return ONLY a JSON object matching this exact schema, with no prose, no markdown code fences, no explanation:

{
  "title": "string — short game title, or empty string if unclear",
  "categories": [
    {
      "name": "STRING",
      "questions": [
        { "points": 200, "question": "string", "answer": "string", "isDailyDouble": false },
        { "points": 400, "question": "string", "answer": "string", "isDailyDouble": false },
        { "points": 600, "question": "string", "answer": "string", "isDailyDouble": false },
        { "points": 800, "question": "string", "answer": "string", "isDailyDouble": false },
        { "points": 1000, "question": "string", "answer": "string", "isDailyDouble": false }
      ]
    }
    // ... exactly 5 categories total
  ]
}

Empty slots use "" for question and answer. Never use null. Points must be 200/400/600/800/1000 in that order within each category.`;

// -----------------------------------------------------------------------------
// Response shape helpers
// -----------------------------------------------------------------------------
type Clue = { points: number; question: string; answer: string; isDailyDouble: boolean };
type Category = { name: string; questions: Clue[] };
type GameState = { title: string; categories: Category[] };

function blankGame(): GameState {
  const categories: Category[] = [];
  for (let c = 0; c < CATEGORY_COUNT; c++) {
    categories.push({
      name: '',
      questions: POINT_LEVELS.map((p) => ({
        points: p,
        question: '',
        answer: '',
        isDailyDouble: false,
      })),
    });
  }
  return { title: '', categories };
}

// Coerce Claude's response into the exact 5x5 shape the tool expects.
// Defensive against wrong array lengths, missing fields, wrong types.
function normalize(input: unknown): GameState {
  const out = blankGame();
  if (!input || typeof input !== 'object') return out;
  const raw = input as Record<string, unknown>;
  if (typeof raw.title === 'string') out.title = raw.title;

  const cats = Array.isArray(raw.categories) ? raw.categories : [];
  for (let c = 0; c < CATEGORY_COUNT; c++) {
    const srcCat = (cats[c] as Record<string, unknown> | undefined) || {};
    out.categories[c].name = typeof srcCat.name === 'string' ? srcCat.name : '';
    const srcQs = Array.isArray(srcCat.questions) ? srcCat.questions : [];
    for (let q = 0; q < POINT_LEVELS.length; q++) {
      // Match by declared points if possible; fall back to positional.
      const byPoints = srcQs.find(
        (x) => x && typeof x === 'object' && (x as Record<string, unknown>).points === POINT_LEVELS[q]
      ) as Record<string, unknown> | undefined;
      const srcQ = (byPoints || (srcQs[q] as Record<string, unknown> | undefined)) || {};
      out.categories[c].questions[q] = {
        points: POINT_LEVELS[q],
        question: typeof srcQ.question === 'string' ? srcQ.question : '',
        answer: typeof srcQ.answer === 'string' ? srcQ.answer : '',
        isDailyDouble: false, // teacher picks manually per system prompt
      };
    }
  }
  return out;
}

// Pull the JSON payload out of a Claude response even if it wraps in ```json fences.
function extractJson(text: string): unknown {
  const trimmed = text.trim();
  // Strip markdown code fence if present.
  const fenced = trimmed.match(/^```(?:json)?\s*\n([\s\S]*?)\n```\s*$/);
  const body = fenced ? fenced[1] : trimmed;
  try {
    return JSON.parse(body);
  } catch {
    // Last-ditch: find the first { and last } and try again.
    const first = body.indexOf('{');
    const last = body.lastIndexOf('}');
    if (first >= 0 && last > first) {
      try {
        return JSON.parse(body.slice(first, last + 1));
      } catch {
        /* fall through */
      }
    }
    throw new Error('Model did not return valid JSON');
  }
}

// -----------------------------------------------------------------------------
// Route
// -----------------------------------------------------------------------------
export const POST: APIRoute = async ({ request }) => {
  // Body parse.
  let body: { mode?: string; text?: string };
  try {
    body = await request.json();
  } catch {
    return json({ ok: false, error: 'Invalid request body.' }, 400);
  }

  if (body?.mode !== 'parse') {
    return json({ ok: false, error: 'Unsupported mode.' }, 400);
  }

  const text = typeof body.text === 'string' ? body.text.trim() : '';
  if (!text) {
    return json({ ok: false, error: 'Paste some questions first.' }, 400);
  }
  if (text.length > 20000) {
    return json(
      { ok: false, error: 'That is a lot of text. Try trimming to about 100 items or fewer.' },
      400
    );
  }

  // Rate limit.
  const rl = getRatelimit();
  if (rl) {
    const ip = getClientIp(request);
    const { success, remaining } = await rl.limit(ip);
    if (!success) {
      return json(
        {
          ok: false,
          error:
            "You've hit today's generation limit (15 boards / day). Try again tomorrow, or fill the board manually.",
        },
        429
      );
    }
    // Non-fatal debug header for our own future sanity.
    console.log(`[jeopardy/generate] ip=${ip} remaining=${remaining}`);
  }

  // Anthropic call.
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    console.error('[jeopardy/generate] ANTHROPIC_API_KEY missing');
    return json({ ok: false, error: 'Server misconfigured. Try again later.' }, 500);
  }

  const client = new Anthropic({ apiKey });

  try {
    const resp = await client.messages.create({
      model: HAIKU_MODEL,
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: 'user',
          content: `Here is the teacher's list. Return only the JSON.\n\n---\n${text}\n---`,
        },
      ],
    });

    // Extract the first text block.
    const textBlock = resp.content.find((b) => b.type === 'text');
    if (!textBlock || textBlock.type !== 'text') {
      throw new Error('Model returned no text content');
    }
    const parsed = extractJson(textBlock.text);
    const game = normalize(parsed);

    // Basic sanity: did we get at least one filled clue back?
    let filled = 0;
    for (const cat of game.categories) {
      for (const q of cat.questions) {
        if (q.question && q.answer) filled++;
      }
    }
    if (filled === 0) {
      return json(
        {
          ok: false,
          error:
            "The model couldn't extract questions and answers from that. Make sure each item has both a question and an answer.",
        },
        422
      );
    }

    return json({ ok: true, data: game, meta: { filled } }, 200);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown error';
    console.error('[jeopardy/generate] anthropic error:', msg);
    return json({ ok: false, error: 'Generation failed. Try again in a moment.' }, 502);
  }
};

function json(payload: unknown, status: number): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}
